import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from geoalchemy2.shape import from_shape, to_shape
from shapely.geometry import shape, mapping
from shapely import wkt

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.models.field import Field
from app.schemas.field import FieldCreate, FieldUpdate, FieldOut, FieldSummary

router = APIRouter(prefix="/fields", tags=["Fields"])


def _geojson_to_wkb(geojson_geom: dict):
    """Convierte un dict GeoJSON Polygon a geometría PostGIS (WKB con SRID 4326)."""
    geom = shape(geojson_geom)  # shapely geometry
    return from_shape(geom, srid=4326)


def _field_to_out(field: Field) -> FieldOut:
    geom_shape = to_shape(field.geometry)
    return FieldOut(
        id=field.id,
        name=field.name,
        description=field.description,
        crop=field.crop,
        area_ha=float(field.area_ha) if field.area_ha is not None else None,
        owner_id=field.owner_id,
        geometry=mapping(geom_shape),  # GeoJSON dict
        created_at=field.created_at,
        updated_at=field.updated_at,
    )


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("/", response_model=FieldOut, status_code=status.HTTP_201_CREATED)
async def create_field(
    payload: FieldCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """
    Crear una parcela con geometría poligonal en GeoJSON.

    Ejemplo de `geometry`:
    ```json
    {
      "type": "Polygon",
      "coordinates": [[
        [-86.910, 40.425], [-86.905, 40.425],
        [-86.905, 40.420], [-86.910, 40.420],
        [-86.910, 40.425]
      ]]
    }
    ```
    """
    geom_wkb = _geojson_to_wkb(payload.geometry.model_dump())

    # Calcular área en hectáreas usando proyección EPSG:3857 (metros)
    area_ha = payload.area_ha
    if area_ha is None:
        geom_shape = shape(payload.geometry.model_dump())
        # Aproximación en grados → transformar a metros (solo válido para áreas pequeñas)
        from shapely.ops import transform
        import pyproj
        proj_wgs84 = pyproj.CRS("EPSG:4326")
        proj_utm = pyproj.CRS("EPSG:3857")
        project = pyproj.Transformer.from_crs(proj_wgs84, proj_utm, always_xy=True).transform
        geom_m = transform(project, geom_shape)
        area_ha = geom_m.area / 10_000  # m² → ha

    field = Field(
        id=str(uuid.uuid4()),
        name=payload.name,
        description=payload.description,
        crop=payload.crop,
        owner_id=user_id,
        geometry=geom_wkb,
        area_ha=round(area_ha, 4),
    )
    db.add(field)
    await db.commit()
    await db.refresh(field)
    return _field_to_out(field)


@router.get("/", response_model=list[FieldSummary])
async def list_fields(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Listar las parcelas del usuario autenticado."""
    result = await db.execute(
        select(Field).where(Field.owner_id == user_id).order_by(Field.name)
    )
    fields = result.scalars().all()
    return [
        FieldSummary(
            id=f.id,
            name=f.name,
            crop=f.crop,
            area_ha=float(f.area_ha) if f.area_ha is not None else None,
        )
        for f in fields
    ]


@router.get("/{field_id}", response_model=FieldOut)
async def get_field(
    field_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    field = await _get_owned_field(db, field_id, user_id)
    return _field_to_out(field)


@router.patch("/{field_id}", response_model=FieldOut)
async def update_field(
    field_id: str,
    payload: FieldUpdate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Actualizar nombre, descripción o geometría de una parcela."""
    field = await _get_owned_field(db, field_id, user_id)

    updates: dict = {}
    if payload.name is not None:
        updates["name"] = payload.name
    if payload.description is not None:
        updates["description"] = payload.description
    if payload.crop is not None:
        updates["crop"] = payload.crop
    if payload.area_ha is not None:
        updates["area_ha"] = payload.area_ha
    if payload.geometry is not None:
        updates["geometry"] = _geojson_to_wkb(payload.geometry.model_dump())

    if updates:
        from datetime import datetime, timezone
        updates["updated_at"] = datetime.now(timezone.utc)
        await db.execute(update(Field).where(Field.id == field_id).values(**updates))
        await db.commit()
        await db.refresh(field)

    return _field_to_out(field)


@router.delete("/{field_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_field(
    field_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    await _get_owned_field(db, field_id, user_id)
    await db.execute(delete(Field).where(Field.id == field_id))
    await db.commit()


@router.get("/{field_id}/geojson")
async def get_field_geojson(
    field_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """
    Exportar la parcela como GeoJSON Feature.
    Útil para importar en QGIS u otras herramientas SIG.
    """
    field = await _get_owned_field(db, field_id, user_id)
    geom_shape = to_shape(field.geometry)
    return {
        "type": "Feature",
        "properties": {
            "id": field.id,
            "name": field.name,
            "crop": field.crop,
            "area_ha": float(field.area_ha) if field.area_ha else None,
        },
        "geometry": mapping(geom_shape),
    }


# ── Helper ─────────────────────────────────────────────────────────────────────

async def _get_owned_field(db: AsyncSession, field_id: str, user_id: str) -> Field:
    result = await db.execute(select(Field).where(Field.id == field_id))
    field = result.scalar_one_or_none()
    if not field:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Field not found")
    if field.owner_id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your field")
    return field

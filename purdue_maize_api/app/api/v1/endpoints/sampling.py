from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from geoalchemy2.shape import from_shape
from shapely.geometry import Point

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.models.sampling import SamplingSession, SamplingPoint
from app.schemas.sampling import SamplingSessionCreate, SamplingSessionOut, SamplingPointOut

router = APIRouter(prefix="/sampling", tags=["Sampling"])


@router.post("/sessions", response_model=SamplingSessionOut, status_code=status.HTTP_201_CREATED)
async def create_session(
    payload: SamplingSessionCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Crear una sesión de muestreo con sus puntos georreferenciados."""
    session = SamplingSession(
        field_id=payload.field_id,
        created_by=user_id,
        sampling_type=payload.sampling_type,
        session_date=payload.session_date,
        notes=payload.notes,
    )
    for pt in payload.points:
        geom = from_shape(Point(pt.location.longitude, pt.location.latitude), srid=4326)
        session.points.append(
            SamplingPoint(
                point_code=pt.point_code,
                location=geom,
                altitude_m=pt.location.altitude_m,
                recorded_at=pt.recorded_at,
                sync_status=pt.sync_status,
            )
        )
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return _session_to_out(session)


@router.get("/sessions/{session_id}", response_model=SamplingSessionOut)
async def get_session(
    session_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(SamplingSession).where(SamplingSession.id == session_id))
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    return _session_to_out(session)


@router.get("/sessions", response_model=list[SamplingSessionOut])
async def list_sessions(
    field_id: str | None = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    q = select(SamplingSession).where(SamplingSession.created_by == user_id)
    if field_id:
        q = q.where(SamplingSession.field_id == field_id)
    result = await db.execute(q)
    return [_session_to_out(s) for s in result.scalars().all()]


def _session_to_out(session: SamplingSession) -> SamplingSessionOut:
    from geoalchemy2.shape import to_shape
    points_out = []
    for pt in session.points:
        shape = to_shape(pt.location)
        points_out.append(
            SamplingPointOut(
                id=pt.id,
                session_id=pt.session_id,
                point_code=pt.point_code,
                latitude=shape.y,
                longitude=shape.x,
                altitude_m=pt.altitude_m,
                sync_status=pt.sync_status,
                recorded_at=pt.recorded_at,
                created_at=pt.created_at,
            )
        )
    return SamplingSessionOut(
        id=session.id,
        field_id=session.field_id,
        sampling_type=session.sampling_type,
        session_date=session.session_date,
        notes=session.notes,
        created_at=session.created_at,
        points=points_out,
    )

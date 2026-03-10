from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timezone

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.models.modeling import ModelRun, ModelResult, ModelStatus
from app.schemas.modeling import ModelRunCreate, ModelRunOut, ModelResultOut, ModelResultsGeoJSON

router = APIRouter(prefix="/modeling", tags=["Modeling"])


@router.post("/runs", response_model=ModelRunOut, status_code=status.HTTP_202_ACCEPTED)
async def submit_model_run(
    payload: ModelRunCreate,
    background_tasks: BackgroundTasks,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """
    Enviar parámetros para ejecutar un modelo predictivo.
    La ejecución ocurre en background; el cliente puede hacer polling sobre el status.
    """
    run = ModelRun(
        field_id=payload.field_id,
        disease_id=payload.disease_id,
        created_by=user_id,
        model_type=payload.model_type,
        prediction_horizon_days=payload.prediction_horizon_days,
        parameters=payload.parameters,
        status=ModelStatus.PENDING,
    )
    db.add(run)
    await db.commit()
    await db.refresh(run)

    # Ejecutar modelo en background (reemplazar con Celery/worker en producción)
    background_tasks.add_task(_run_model_background, run.id)
    return _run_to_out(run)


@router.get("/runs/{run_id}", response_model=ModelRunOut)
async def get_run_status(
    run_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Consultar estado y métricas de una ejecución de modelo."""
    result = await db.execute(select(ModelRun).where(ModelRun.id == run_id))
    run = result.scalar_one_or_none()
    if not run:
        raise HTTPException(status_code=404, detail="Model run not found")
    return _run_to_out(run)


@router.get("/runs", response_model=list[ModelRunOut])
async def list_runs(
    field_id: str | None = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    q = select(ModelRun).where(ModelRun.created_by == user_id).order_by(ModelRun.created_at.desc())
    if field_id:
        q = q.where(ModelRun.field_id == field_id)
    result = await db.execute(q)
    return [_run_to_out(r) for r in result.scalars().all()]


@router.get("/runs/{run_id}/results", response_model=list[ModelResultOut])
async def get_results(
    run_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Obtener resultados tabulares (para gráficas tiempo-riesgo)."""
    result = await db.execute(
        select(ModelResult).where(ModelResult.run_id == run_id).order_by(ModelResult.result_date)
    )
    results = result.scalars().all()
    return [_result_to_out(r) for r in results]


@router.get("/runs/{run_id}/results/geojson", response_model=ModelResultsGeoJSON)
async def get_results_geojson(
    run_id: str,
    result_date: str | None = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """
    Exportar resultados como GeoJSON FeatureCollection para mapas de riesgo en SIG.
    Opcionalmente filtrar por fecha.
    """
    from geoalchemy2.shape import to_shape
    q = select(ModelResult).where(ModelResult.run_id == run_id, ModelResult.location.isnot(None))
    if result_date:
        q = q.where(ModelResult.result_date == result_date)
    result = await db.execute(q)
    results = result.scalars().all()

    features = []
    for r in results:
        shape = to_shape(r.location)
        features.append({
            "type": "Feature",
            "geometry": {"type": "Point", "coordinates": [shape.x, shape.y]},
            "properties": {
                "result_date": str(r.result_date),
                "risk_level": r.risk_level,
                "predicted_incidence_pct": float(r.predicted_incidence_pct) if r.predicted_incidence_pct else None,
                "confidence": float(r.confidence) if r.confidence else None,
            },
        })
    return ModelResultsGeoJSON(features=features)


async def _run_model_background(run_id: str):
    """
    Placeholder para la ejecución del modelo en background.
    En producción: delegar a Celery o un servicio de modelado separado.
    """
    # TODO: implementar lógica de modelado
    # 1. Cargar datos de la parcela (observaciones históricas, clima, imágenes)
    # 2. Ejecutar modelo (regression / RF / LSTM spatiotemporal)
    # 3. Guardar ModelResult[] en DB
    # 4. Actualizar ModelRun.status = COMPLETED y ModelRun.metrics
    pass


def _run_to_out(run: ModelRun) -> ModelRunOut:
    return ModelRunOut(
        id=run.id,
        field_id=run.field_id,
        disease_id=run.disease_id,
        model_type=run.model_type,
        prediction_horizon_days=run.prediction_horizon_days,
        parameters=run.parameters,
        status=run.status,
        metrics=run.metrics,
        error_message=run.error_message,
        started_at=run.started_at,
        completed_at=run.completed_at,
        created_at=run.created_at,
    )


def _result_to_out(r: ModelResult) -> ModelResultOut:
    from geoalchemy2.shape import to_shape
    lat = lon = None
    if r.location is not None:
        shape = to_shape(r.location)
        lat, lon = shape.y, shape.x
    return ModelResultOut(
        id=r.id,
        run_id=r.run_id,
        result_date=r.result_date,
        latitude=lat,
        longitude=lon,
        risk_level=r.risk_level,
        predicted_incidence_pct=float(r.predicted_incidence_pct) if r.predicted_incidence_pct else None,
        predicted_severity_value=float(r.predicted_severity_value) if r.predicted_severity_value else None,
        confidence=float(r.confidence) if r.confidence else None,
    )

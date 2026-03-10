import os
import uuid
import aiofiles
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.core.config import get_settings
from app.models.observation import Observation, MediaFile, MediaType
from app.schemas.observation import ObservationCreate, ObservationOut, MediaFileOut

router = APIRouter(prefix="/observations", tags=["Data Capture"])
settings = get_settings()

ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/heic"}
ALLOWED_AUDIO_TYPES = {"audio/mpeg", "audio/mp4", "audio/wav", "audio/ogg", "audio/m4a"}


@router.post("/", response_model=ObservationOut, status_code=status.HTTP_201_CREATED)
async def create_observation(
    payload: ObservationCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Registrar incidencia/severidad de una enfermedad en un punto de muestreo."""
    obs = Observation(**payload.model_dump())
    db.add(obs)
    await db.commit()
    await db.refresh(obs)
    return _obs_to_out(obs)


@router.post("/{observation_id}/media", response_model=MediaFileOut, status_code=status.HTTP_201_CREATED)
async def upload_media(
    observation_id: str,
    file: UploadFile = File(...),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """
    Adjuntar imagen o audio a una observación.
    Accepts: JPEG/PNG/WEBP para imágenes; MP3/WAV/M4A/OGG para audio.
    """
    result = await db.execute(select(Observation).where(Observation.id == observation_id))
    obs = result.scalar_one_or_none()
    if not obs:
        raise HTTPException(status_code=404, detail="Observation not found")

    mime = file.content_type or ""
    if mime in ALLOWED_IMAGE_TYPES:
        media_type = MediaType.IMAGE
    elif mime in ALLOWED_AUDIO_TYPES:
        media_type = MediaType.AUDIO
    else:
        raise HTTPException(status_code=415, detail=f"Unsupported media type: {mime}")

    file_id = str(uuid.uuid4())
    ext = os.path.splitext(file.filename or "")[1] or _ext_from_mime(mime)
    relative_path = f"{observation_id}/{file_id}{ext}"
    full_path = os.path.join(settings.MEDIA_DIR, relative_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)

    content = await file.read()
    max_bytes = (settings.MAX_IMAGE_MB if media_type == MediaType.IMAGE else settings.MAX_AUDIO_MB) * 1024 * 1024
    if len(content) > max_bytes:
        raise HTTPException(status_code=413, detail="File too large")

    async with aiofiles.open(full_path, "wb") as f:
        await f.write(content)

    media = MediaFile(
        id=file_id,
        observation_id=observation_id,
        media_type=media_type,
        original_filename=file.filename,
        file_path=relative_path,
        file_size_bytes=len(content),
        mime_type=mime,
    )
    db.add(media)
    await db.commit()
    await db.refresh(media)
    return _media_to_out(media)


@router.get("/{observation_id}", response_model=ObservationOut)
async def get_observation(
    observation_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Observation).where(Observation.id == observation_id))
    obs = result.scalar_one_or_none()
    if not obs:
        raise HTTPException(status_code=404, detail="Observation not found")
    return _obs_to_out(obs)


@router.get("/", response_model=list[ObservationOut])
async def list_observations(
    sampling_point_id: str | None = None,
    disease_id: int | None = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    q = select(Observation)
    if sampling_point_id:
        q = q.where(Observation.sampling_point_id == sampling_point_id)
    if disease_id:
        q = q.where(Observation.disease_id == disease_id)
    result = await db.execute(q)
    return [_obs_to_out(o) for o in result.scalars().all()]


def _obs_to_out(obs: Observation) -> ObservationOut:
    disease_name = obs.disease.name if obs.disease else None
    return ObservationOut(
        id=obs.id,
        sampling_point_id=obs.sampling_point_id,
        disease_id=obs.disease_id,
        disease_name=disease_name,
        incidence_pct=float(obs.incidence_pct) if obs.incidence_pct is not None else None,
        severity_value=float(obs.severity_value) if obs.severity_value is not None else None,
        severity_scale=obs.severity_scale,
        cultivar=obs.cultivar,
        phenological_stage=obs.phenological_stage,
        notes=obs.notes,
        observed_at=obs.observed_at,
        sync_status=obs.sync_status,
        created_at=obs.created_at,
        media_files=[_media_to_out(m) for m in obs.media_files],
    )


def _media_to_out(m: MediaFile) -> MediaFileOut:
    return MediaFileOut(
        id=m.id,
        media_type=m.media_type,
        original_filename=m.original_filename,
        file_size_bytes=m.file_size_bytes,
        duration_seconds=float(m.duration_seconds) if m.duration_seconds else None,
        mime_type=m.mime_type,
        created_at=m.created_at,
        url=f"/api/v1/media/{m.id}",
    )


def _ext_from_mime(mime: str) -> str:
    mapping = {
        "image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp",
        "audio/mpeg": ".mp3", "audio/wav": ".wav", "audio/mp4": ".m4a",
        "audio/ogg": ".ogg", "audio/m4a": ".m4a",
    }
    return mapping.get(mime, "")

from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from app.models.observation import SeverityScale, SyncStatus, MediaType


class MediaFileOut(BaseModel):
    id: str
    media_type: MediaType
    original_filename: Optional[str]
    file_size_bytes: Optional[int]
    duration_seconds: Optional[float]
    mime_type: Optional[str]
    created_at: datetime
    url: str  # Computed field: /api/v1/media/{id}

    model_config = {"from_attributes": True}


class ObservationCreate(BaseModel):
    sampling_point_id: str
    disease_id: int
    incidence_pct: Optional[float] = Field(None, ge=0, le=100)
    severity_value: Optional[float] = Field(None, ge=0)
    severity_scale: Optional[SeverityScale] = None
    cultivar: Optional[str] = None
    phenological_stage: Optional[str] = None
    planting_date: Optional[str] = None
    irrigation: Optional[bool] = None
    fungicide_applied: Optional[bool] = None
    fertilization_notes: Optional[str] = None
    notes: Optional[str] = None
    observed_at: datetime
    sync_status: SyncStatus = SyncStatus.SYNCED


class ObservationOut(BaseModel):
    id: str
    sampling_point_id: str
    disease_id: int
    disease_name: Optional[str] = None
    incidence_pct: Optional[float]
    severity_value: Optional[float]
    severity_scale: Optional[SeverityScale]
    cultivar: Optional[str]
    phenological_stage: Optional[str]
    notes: Optional[str]
    observed_at: datetime
    sync_status: SyncStatus
    created_at: datetime
    media_files: list[MediaFileOut] = []

    model_config = {"from_attributes": True}


class ObservationFilter(BaseModel):
    field_id: Optional[str] = None
    disease_id: Optional[int] = None
    date_from: Optional[str] = None
    date_to: Optional[str] = None
    min_incidence: Optional[float] = None
    max_incidence: Optional[float] = None
    cultivar: Optional[str] = None

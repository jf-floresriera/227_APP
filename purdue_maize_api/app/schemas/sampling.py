from pydantic import BaseModel, Field
from datetime import datetime, date
from typing import Optional
from app.models.sampling import SamplingType, SyncStatus


class PointCoords(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    altitude_m: Optional[float] = None


class SamplingPointCreate(BaseModel):
    point_code: Optional[str] = None
    location: PointCoords
    recorded_at: datetime
    sync_status: SyncStatus = SyncStatus.SYNCED


class SamplingPointOut(BaseModel):
    id: str
    session_id: str
    point_code: Optional[str]
    latitude: float
    longitude: float
    altitude_m: Optional[float]
    sync_status: SyncStatus
    recorded_at: datetime
    created_at: datetime

    model_config = {"from_attributes": True}


class SamplingSessionCreate(BaseModel):
    field_id: str
    sampling_type: SamplingType
    session_date: date
    notes: Optional[str] = None
    points: list[SamplingPointCreate] = []


class SamplingSessionOut(BaseModel):
    id: str
    field_id: str
    sampling_type: SamplingType
    session_date: date
    notes: Optional[str]
    created_at: datetime
    points: list[SamplingPointOut] = []

    model_config = {"from_attributes": True}

from pydantic import BaseModel, Field
from datetime import datetime, date
from typing import Optional, Any
from app.models.modeling import ModelStatus, RiskLevel


class ModelRunCreate(BaseModel):
    field_id: str
    disease_id: int
    model_type: str = Field(..., examples=["regression", "random_forest", "lstm_spatiotemporal"])
    prediction_horizon_days: int = Field(14, ge=1, le=90)
    parameters: Optional[dict[str, Any]] = Field(
        default=None,
        examples=[{"use_climate": True, "use_history": True, "use_imagery": False, "use_management": True}],
    )


class ModelRunOut(BaseModel):
    id: str
    field_id: str
    disease_id: int
    model_type: str
    prediction_horizon_days: int
    parameters: Optional[dict[str, Any]]
    status: ModelStatus
    metrics: Optional[dict[str, Any]]
    error_message: Optional[str]
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    created_at: datetime

    model_config = {"from_attributes": True}


class ModelResultOut(BaseModel):
    id: str
    run_id: str
    result_date: date
    latitude: Optional[float]
    longitude: Optional[float]
    risk_level: Optional[RiskLevel]
    predicted_incidence_pct: Optional[float]
    predicted_severity_value: Optional[float]
    confidence: Optional[float]

    model_config = {"from_attributes": True}


class ModelResultsGeoJSON(BaseModel):
    """GeoJSON FeatureCollection para exportar mapa de riesgo."""
    type: str = "FeatureCollection"
    features: list[dict]

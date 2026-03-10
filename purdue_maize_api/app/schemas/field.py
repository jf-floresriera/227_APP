from pydantic import BaseModel, Field, field_validator
from typing import Optional, Any
from datetime import datetime


# ── GeoJSON helpers ───────────────────────────────────────────────────────────

class GeoJSONPolygon(BaseModel):
    """GeoJSON Polygon geometry (sin CRS — se asume WGS84 / EPSG:4326)."""
    type: str = "Polygon"
    coordinates: list[list[list[float]]]  # [ [ [lon,lat], ... ] ]

    @field_validator("type")
    @classmethod
    def must_be_polygon(cls, v: str) -> str:
        if v != "Polygon":
            raise ValueError("geometry.type must be 'Polygon'")
        return v

    @field_validator("coordinates")
    @classmethod
    def must_have_ring(cls, v: list) -> list:
        if not v or len(v[0]) < 4:
            raise ValueError("Polygon must have at least one ring with ≥ 4 positions")
        return v


# ── Request / Response schemas ─────────────────────────────────────────────────

class FieldCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    crop: str = Field("maize", max_length=100)
    geometry: GeoJSONPolygon
    area_ha: Optional[float] = Field(None, ge=0)


class FieldUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    crop: Optional[str] = None
    geometry: Optional[GeoJSONPolygon] = None
    area_ha: Optional[float] = Field(None, ge=0)


class FieldOut(BaseModel):
    id: str
    name: str
    description: Optional[str]
    crop: str
    area_ha: Optional[float]
    owner_id: str
    # geometry devuelta como GeoJSON para que la app pueda dibujarlo en el mapa
    geometry: dict[str, Any]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class FieldSummary(BaseModel):
    """Vista reducida para listas y dropdowns."""
    id: str
    name: str
    crop: str
    area_ha: Optional[float]

    model_config = {"from_attributes": True}

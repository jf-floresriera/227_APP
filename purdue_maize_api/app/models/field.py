import uuid
from datetime import datetime, timezone
from sqlalchemy import String, DateTime, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from geoalchemy2 import Geometry
from app.core.database import Base


class Field(Base):
    """Parcela o lote agrícola con geometría espacial (polígono)."""
    __tablename__ = "fields"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    crop: Mapped[str] = mapped_column(String(100), default="maize")
    owner_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), nullable=False)

    # PostGIS geometry: polygon in WGS84 (EPSG:4326)
    geometry: Mapped[object] = mapped_column(Geometry(geometry_type="POLYGON", srid=4326), nullable=False)

    area_ha: Mapped[float | None] = mapped_column()
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    owner: Mapped["User"] = relationship(back_populates="fields")
    sampling_sessions: Mapped[list["SamplingSession"]] = relationship(back_populates="field")
    model_runs: Mapped[list["ModelRun"]] = relationship(back_populates="field")

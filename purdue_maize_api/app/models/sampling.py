import uuid
from datetime import datetime, date, timezone
from enum import Enum
from sqlalchemy import String, DateTime, Date, ForeignKey, Text, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from geoalchemy2 import Geometry
from app.core.database import Base


class SamplingType(str, Enum):
    SYSTEMATIC = "systematic"    # Grilla regular
    RANDOM = "random"            # Aleatorio simple
    TRANSECT = "transect"        # Transectos
    DIRECTED = "directed"        # Dirigido (sospecha de enfermedad)


class SyncStatus(str, Enum):
    PENDING = "pending"
    SYNCED = "synced"


class SamplingSession(Base):
    """Sesión de muestreo: agrupa puntos levantados en una salida de campo."""
    __tablename__ = "sampling_sessions"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    field_id: Mapped[str] = mapped_column(String, ForeignKey("fields.id"), nullable=False)
    created_by: Mapped[str] = mapped_column(String, ForeignKey("users.id"), nullable=False)
    sampling_type: Mapped[SamplingType] = mapped_column(SAEnum(SamplingType), nullable=False)
    session_date: Mapped[date] = mapped_column(Date, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    field: Mapped["Field"] = relationship(back_populates="sampling_sessions")
    created_by_user: Mapped["User"] = relationship(back_populates="sampling_sessions")
    points: Mapped[list["SamplingPoint"]] = relationship(back_populates="session", cascade="all, delete-orphan")


class SamplingPoint(Base):
    """Punto georreferenciado dentro de una sesión de muestreo."""
    __tablename__ = "sampling_points"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    session_id: Mapped[str] = mapped_column(String, ForeignKey("sampling_sessions.id"), nullable=False)
    point_code: Mapped[str | None] = mapped_column(String(50))

    # PostGIS point in WGS84
    location: Mapped[object] = mapped_column(Geometry(geometry_type="POINT", srid=4326), nullable=False)

    altitude_m: Mapped[float | None] = mapped_column()
    sync_status: Mapped[SyncStatus] = mapped_column(SAEnum(SyncStatus), default=SyncStatus.SYNCED)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    session: Mapped["SamplingSession"] = relationship(back_populates="points")
    observations: Mapped[list["Observation"]] = relationship(back_populates="sampling_point", cascade="all, delete-orphan")

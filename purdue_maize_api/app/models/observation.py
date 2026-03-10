import uuid
from datetime import datetime, timezone
from enum import Enum
from sqlalchemy import String, DateTime, ForeignKey, Text, Numeric, Integer
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class SeverityScale(str, Enum):
    PERCENTAGE = "percentage"  # 0–100 % área foliar afectada
    SCALE_1_9 = "1-9"          # Escala ordinal 1 al 9
    SCALE_1_5 = "1-5"


class SyncStatus(str, Enum):
    PENDING = "pending"
    SYNCED = "synced"


class MediaType(str, Enum):
    IMAGE = "image"
    AUDIO = "audio"


class Observation(Base):
    """
    Registro de enfermedad en un punto de muestreo.
    Un punto puede tener múltiples observaciones (una por enfermedad detectada).
    """
    __tablename__ = "observations"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    sampling_point_id: Mapped[str] = mapped_column(String, ForeignKey("sampling_points.id"), nullable=False)
    disease_id: Mapped[int] = mapped_column(Integer, ForeignKey("diseases.id"), nullable=False)

    # Incidencia: % plantas afectadas en la unidad de muestreo (0–100)
    incidence_pct: Mapped[float | None] = mapped_column(Numeric(5, 2))

    # Severidad: valor numérico + escala para interpretar
    severity_value: Mapped[float | None] = mapped_column(Numeric(5, 2))
    severity_scale: Mapped[SeverityScale | None] = mapped_column(SAEnum(SeverityScale))

    # Contexto agronómico
    cultivar: Mapped[str | None] = mapped_column(String(200))
    phenological_stage: Mapped[str | None] = mapped_column(String(100))  # VT, R1, V6, etc.
    planting_date: Mapped[str | None] = mapped_column(String(50))
    irrigation: Mapped[bool | None] = mapped_column()
    fungicide_applied: Mapped[bool | None] = mapped_column()
    fertilization_notes: Mapped[str | None] = mapped_column(Text)

    notes: Mapped[str | None] = mapped_column(Text)
    observed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    sync_status: Mapped[SyncStatus] = mapped_column(SAEnum(SyncStatus), default=SyncStatus.SYNCED)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    sampling_point: Mapped["SamplingPoint"] = relationship(back_populates="observations")
    disease: Mapped["Disease"] = relationship(back_populates="observations")
    media_files: Mapped[list["MediaFile"]] = relationship(back_populates="observation", cascade="all, delete-orphan")


class MediaFile(Base):
    """Archivo multimedia adjunto a una observación (imagen o audio)."""
    __tablename__ = "media_files"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    observation_id: Mapped[str] = mapped_column(String, ForeignKey("observations.id"), nullable=False)
    media_type: Mapped[MediaType] = mapped_column(SAEnum(MediaType), nullable=False)

    original_filename: Mapped[str | None] = mapped_column(String(500))
    file_path: Mapped[str] = mapped_column(String(1000), nullable=False)
    file_size_bytes: Mapped[int | None] = mapped_column(Integer)
    duration_seconds: Mapped[float | None] = mapped_column(Numeric(8, 2))  # solo audio
    mime_type: Mapped[str | None] = mapped_column(String(100))

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    observation: Mapped["Observation"] = relationship(back_populates="media_files")

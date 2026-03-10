import uuid
from datetime import datetime, date, timezone
from enum import Enum
from sqlalchemy import String, DateTime, Date, ForeignKey, Text, Numeric, Integer, JSON
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from geoalchemy2 import Geometry
from app.core.database import Base


class ModelStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"


class RiskLevel(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    VERY_HIGH = "very_high"


class ModelRun(Base):
    """
    Ejecución de un modelo predictivo para una parcela y enfermedad.
    El backend recibe los parámetros, ejecuta el modelo y almacena resultados.
    """
    __tablename__ = "model_runs"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    field_id: Mapped[str] = mapped_column(String, ForeignKey("fields.id"), nullable=False)
    disease_id: Mapped[int] = mapped_column(Integer, ForeignKey("diseases.id"), nullable=False)
    created_by: Mapped[str] = mapped_column(String, ForeignKey("users.id"), nullable=False)

    model_type: Mapped[str] = mapped_column(String(100), nullable=False)  # e.g. "regression", "rf", "lstm"
    prediction_horizon_days: Mapped[int] = mapped_column(Integer, default=14)

    # Configuración JSON: variables activas (climate, history, imagery, management)
    parameters: Mapped[dict | None] = mapped_column(JSON)

    status: Mapped[ModelStatus] = mapped_column(SAEnum(ModelStatus), default=ModelStatus.PENDING)
    error_message: Mapped[str | None] = mapped_column(Text)

    # Métricas de ajuste del modelo
    metrics: Mapped[dict | None] = mapped_column(JSON)  # {"rmse": 0.12, "r2": 0.85, ...}

    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    field: Mapped["Field"] = relationship(back_populates="model_runs")
    disease: Mapped["Disease"] = relationship(back_populates="model_runs")
    created_by_user: Mapped["User"] = relationship(back_populates="model_runs")
    results: Mapped[list["ModelResult"]] = relationship(back_populates="run", cascade="all, delete-orphan")


class ModelResult(Base):
    """
    Resultado puntual del modelo: predicción de riesgo en un lugar y momento.
    Permite construir mapas de riesgo y curvas temporales.
    """
    __tablename__ = "model_results"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    run_id: Mapped[str] = mapped_column(String, ForeignKey("model_runs.id"), nullable=False)
    result_date: Mapped[date] = mapped_column(Date, nullable=False)

    # Localización del resultado (puede ser punto de muestreo o celda de grilla)
    location: Mapped[object | None] = mapped_column(Geometry(geometry_type="POINT", srid=4326))

    risk_level: Mapped[RiskLevel | None] = mapped_column(SAEnum(RiskLevel))
    predicted_incidence_pct: Mapped[float | None] = mapped_column(Numeric(5, 2))
    predicted_severity_value: Mapped[float | None] = mapped_column(Numeric(5, 2))
    confidence: Mapped[float | None] = mapped_column(Numeric(5, 4))  # 0–1

    run: Mapped["ModelRun"] = relationship(back_populates="results")

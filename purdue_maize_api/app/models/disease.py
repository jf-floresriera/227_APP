from sqlalchemy import String, Integer, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class Disease(Base):
    """Catálogo de enfermedades del maíz."""
    __tablename__ = "diseases"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False, unique=True)
    common_name: Mapped[str | None] = mapped_column(String(200))
    pathogen: Mapped[str | None] = mapped_column(String(300))
    pathogen_type: Mapped[str | None] = mapped_column(String(50))  # fungal, bacterial, viral
    crop: Mapped[str] = mapped_column(String(100), default="maize")
    description: Mapped[str | None] = mapped_column(Text)

    observations: Mapped[list["Observation"]] = relationship(back_populates="disease")
    model_runs: Mapped[list["ModelRun"]] = relationship(back_populates="disease")


# Seed data — insert via Alembic migration
MAIZE_DISEASES = [
    {"name": "Northern Corn Leaf Blight", "common_name": "Tizón foliar norte", "pathogen": "Exserohilum turcicum", "pathogen_type": "fungal"},
    {"name": "Gray Leaf Spot", "common_name": "Mancha gris", "pathogen": "Cercospora zeae-maydis", "pathogen_type": "fungal"},
    {"name": "Common Rust", "common_name": "Roya común", "pathogen": "Puccinia sorghi", "pathogen_type": "fungal"},
    {"name": "Southern Corn Leaf Blight", "common_name": "Tizón foliar sur", "pathogen": "Cochliobolus heterostrophus", "pathogen_type": "fungal"},
    {"name": "Tar Spot", "common_name": "Mancha de alquitrán", "pathogen": "Phyllachora maydis", "pathogen_type": "fungal"},
    {"name": "Goss's Wilt", "common_name": "Marchitez de Goss", "pathogen": "Clavibacter michiganensis", "pathogen_type": "bacterial"},
    {"name": "Corn Lethal Necrosis", "common_name": "Necrosis letal", "pathogen": "MCMV + SCMV", "pathogen_type": "viral"},
]

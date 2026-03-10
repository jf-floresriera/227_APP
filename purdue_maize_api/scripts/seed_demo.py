"""
Seed script: crea datos demo para probar la app en local.

Crea:
  - 1 usuario demo
  - 2 parcelas (polígonos en Indiana, cerca de Purdue)
  - 1 sesión de muestreo con 6 puntos
  - 6 observaciones (2 enfermedades distintas)

Uso:
  docker compose exec api python scripts/seed_demo.py
  # o directamente:
  python -m scripts.seed_demo
"""
import asyncio
import uuid
from datetime import date, datetime, timezone

from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from geoalchemy2.shape import from_shape
from shapely.geometry import Point, Polygon

from app.core.config import get_settings
from app.core.security import hash_password
from app.models.user import User
from app.models.field import Field
from app.models.disease import Disease
from app.models.sampling import SamplingSession, SamplingPoint
from app.models.observation import Observation

settings = get_settings()

# ── Polígonos demo (West Lafayette, IN) ───────────────────────────────────────

FIELD_1_COORDS = [
    (-86.9200, 40.4220), (-86.9150, 40.4220),
    (-86.9150, 40.4180), (-86.9200, 40.4180),
    (-86.9200, 40.4220),
]

FIELD_2_COORDS = [
    (-86.9100, 40.4300), (-86.9050, 40.4300),
    (-86.9050, 40.4260), (-86.9100, 40.4260),
    (-86.9100, 40.4300),
]

# Puntos de muestreo (dentro del Field 1)
SAMPLING_COORDS = [
    (-86.9195, 40.4215), (-86.9175, 40.4215), (-86.9155, 40.4215),
    (-86.9195, 40.4190), (-86.9175, 40.4190), (-86.9155, 40.4190),
]


async def seed():
    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    Session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with Session() as db:
        print("▶ Verificando si ya existe el usuario demo...")
        from sqlalchemy import select
        existing = await db.execute(select(User).where(User.email == "demo@purdue.edu"))
        if existing.scalar_one_or_none():
            print("  Usuario demo ya existe. Nada que hacer.")
            await engine.dispose()
            return

        print("▶ Creando usuario demo...")
        user = User(
            id=str(uuid.uuid4()),
            email="demo@purdue.edu",
            full_name="Demo Researcher",
            hashed_password=hash_password("purdue2025"),
        )
        db.add(user)
        await db.flush()

        print("▶ Creando parcelas...")
        field1 = Field(
            id=str(uuid.uuid4()),
            name="Agronomy North Field",
            description="Campo experimental norte — maíz híbrido",
            crop="maize",
            owner_id=user.id,
            geometry=from_shape(Polygon(FIELD_1_COORDS), srid=4326),
            area_ha=3.8,
        )
        field2 = Field(
            id=str(uuid.uuid4()),
            name="Agronomy South Field",
            description="Campo experimental sur — ensayo de variedades",
            crop="maize",
            owner_id=user.id,
            geometry=from_shape(Polygon(FIELD_2_COORDS), srid=4326),
            area_ha=2.5,
        )
        db.add_all([field1, field2])
        await db.flush()

        print("▶ Obteniendo enfermedades del catálogo...")
        result = await db.execute(select(Disease))
        diseases = result.scalars().all()
        nlb = next((d for d in diseases if "Blight" in d.name and "Northern" in d.name), diseases[0])
        gls = next((d for d in diseases if "Gray" in d.name), diseases[1])

        print("▶ Creando sesión de muestreo sistemático...")
        session = SamplingSession(
            id=str(uuid.uuid4()),
            field_id=field1.id,
            created_by=user.id,
            sampling_type="systematic",
            session_date=date.today(),
            notes="Evaluación inicial de la temporada. Grilla 3×2.",
        )
        db.add(session)
        await db.flush()

        print("▶ Creando puntos de muestreo y observaciones...")
        incidences = [5.0, 12.0, 8.5, 22.0, 18.0, 6.0]
        severities = [1.5, 3.0, 2.0, 5.5, 4.0, 1.0]

        for i, (lon, lat) in enumerate(SAMPLING_COORDS):
            point = SamplingPoint(
                id=str(uuid.uuid4()),
                session_id=session.id,
                point_code=f"S{i+1:02d}",
                location=from_shape(Point(lon, lat), srid=4326),
                sync_status="synced",
                recorded_at=datetime.now(timezone.utc),
            )
            db.add(point)
            await db.flush()

            # Observación de NCLB
            obs_nlb = Observation(
                id=str(uuid.uuid4()),
                sampling_point_id=point.id,
                disease_id=nlb.id,
                incidence_pct=incidences[i],
                severity_value=severities[i],
                severity_scale="1-9",
                cultivar="DKC61-88RIB",
                phenological_stage="R1",
                observed_at=datetime.now(timezone.utc),
                sync_status="synced",
            )
            db.add(obs_nlb)

            # Observación de GLS solo en algunos puntos
            if i in (2, 3, 4):
                obs_gls = Observation(
                    id=str(uuid.uuid4()),
                    sampling_point_id=point.id,
                    disease_id=gls.id,
                    incidence_pct=incidences[i] * 0.6,
                    severity_value=severities[i] * 0.8,
                    severity_scale="1-9",
                    cultivar="DKC61-88RIB",
                    phenological_stage="R1",
                    observed_at=datetime.now(timezone.utc),
                    sync_status="synced",
                )
                db.add(obs_gls)

        await db.commit()

    await engine.dispose()

    print("\n✅ Seed completado.")
    print("   Email:    demo@purdue.edu")
    print("   Password: purdue2025")
    print("   API Docs: http://localhost:8000/docs")


if __name__ == "__main__":
    asyncio.run(seed())

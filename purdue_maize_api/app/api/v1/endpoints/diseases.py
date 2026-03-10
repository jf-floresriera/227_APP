from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from typing import Optional

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.models.disease import Disease

router = APIRouter(prefix="/diseases", tags=["Diseases"])


class DiseaseOut(BaseModel):
    id: int
    name: str
    common_name: Optional[str]
    pathogen: Optional[str]
    pathogen_type: Optional[str]
    crop: str

    model_config = {"from_attributes": True}


@router.get("/", response_model=list[DiseaseOut])
async def list_diseases(
    crop: str = "maize",
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Disease).where(Disease.crop == crop).order_by(Disease.name))
    return result.scalars().all()

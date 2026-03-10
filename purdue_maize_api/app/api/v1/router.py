from fastapi import APIRouter
from .endpoints import auth, fields, diseases, sampling, observations, modeling

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(fields.router)
api_router.include_router(diseases.router)
api_router.include_router(sampling.router)
api_router.include_router(observations.router)
api_router.include_router(modeling.router)

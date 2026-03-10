from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://maize:maize_secret@localhost:5432/maize_db"

    # Auth
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    # Storage
    MEDIA_DIR: str = "./media"
    MAX_IMAGE_MB: int = 10
    MAX_AUDIO_MB: int = 25

    # App
    PROJECT_NAME: str = "Purdue Maize Disease Monitor"
    API_V1_PREFIX: str = "/api/v1"
    DEBUG: bool = False


@lru_cache
def get_settings() -> Settings:
    return Settings()

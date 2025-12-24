# app/core/config.py
from __future__ import annotations

from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # OpenAI
    openai_api_key: str = ""
    openai_model: str = "gpt-4.1-mini"

    # Upload/storage
    storage_dir: Path = Path("storage")
    upload_dir: Path = Path("storage/uploads")

    # Coffee rules
    min_photos: int = 3
    max_photos: int = 5


settings = Settings()

# klasörleri garantiye al
settings.storage_dir.mkdir(parents=True, exist_ok=True)
settings.upload_dir.mkdir(parents=True, exist_ok=True)

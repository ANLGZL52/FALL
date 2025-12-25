# app/core/config.py
from __future__ import annotations

from pathlib import Path
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # .env dosyasını okur, extra alanları görmezden gelir
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # ✅ OpenAI (alias ile hem OPENAI_API_KEY hem openai_api_key çalışır)
    openai_api_key: str = Field(default="", alias="OPENAI_API_KEY")
    openai_model: str = Field(default="gpt-4.1-mini", alias="OPENAI_MODEL")

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

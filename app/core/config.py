# app/core/config.py
from __future__ import annotations

from pathlib import Path
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


BASE_DIR = Path(__file__).resolve().parents[2]  # .../FALL/app/core -> .../FALL


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=str(BASE_DIR / ".env"), extra="ignore")

    # ✅ DB (TEK NOKTA)
    # Kesin olarak: .../FALL/storage/fall.db
    database_url: str = Field(
        default=f"sqlite:///{(BASE_DIR / 'storage' / 'fall.db').as_posix()}",
        alias="DATABASE_URL",
    )

    # ✅ OpenAI
    openai_api_key: str = Field(default="", alias="OPENAI_API_KEY")
    openai_model: str = Field(default="gpt-4.1-mini", alias="OPENAI_MODEL")

    # ✅ Storage / uploads (tek kök)
    storage_dir: Path = BASE_DIR / "storage"
    upload_dir: Path = BASE_DIR / "storage" / "uploads"

    # Coffee rules
    min_photos: int = 3
    max_photos: int = 5


settings = Settings()

# klasörleri garantiye al
settings.storage_dir.mkdir(parents=True, exist_ok=True)
settings.upload_dir.mkdir(parents=True, exist_ok=True)

# app/core/config.py
import os
from dataclasses import dataclass

@dataclass(frozen=True)
class Settings:
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "").strip()

    MIN_PHOTOS: int = int(os.getenv("MIN_PHOTOS", "3"))
    MAX_PHOTOS: int = int(os.getenv("MAX_PHOTOS", "5"))

    # Görsel analiz + fal üretimi için model
    # (OpenAI Python SDK 2.x ile Responses API)
    OPENAI_MODEL: str = os.getenv("OPENAI_MODEL", "gpt-4.1-mini")

    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", "storage/uploads")

settings = Settings()

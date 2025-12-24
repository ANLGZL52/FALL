# app/core/config.py
import os
from dataclasses import dataclass
from pathlib import Path

def _project_root() -> Path:
    # app/core/config.py -> app/core -> app -> PROJECT_ROOT
    return Path(__file__).resolve().parents[2]

@dataclass(frozen=True)
class Settings:
    # Secrets
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "").strip()

    # Coffee flow
    MIN_PHOTOS: int = int(os.getenv("MIN_PHOTOS", "3"))
    MAX_PHOTOS: int = int(os.getenv("MAX_PHOTOS", "5"))

    # OpenAI model (Responses API)
    OPENAI_MODEL: str = os.getenv("OPENAI_MODEL", "gpt-4.1-mini")

    # Upload
    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", "storage/uploads")  # relative OK
    MAX_UPLOAD_MB: int = int(os.getenv("MAX_UPLOAD_MB", "8"))     # tek foto max 8MB
    ALLOWED_EXTS: tuple[str, ...] = (".jpg", ".jpeg", ".png", ".webp")

    # (opsiyonel ama çok faydalı) görseli küçült
    IMAGE_MAX_DIM: int = int(os.getenv("IMAGE_MAX_DIM", "1280"))  # max genişlik/yükseklik

    @property
    def upload_base(self) -> Path:
        p = Path(self.UPLOAD_DIR)
        if p.is_absolute():
            return p
        return _project_root() / p

settings = Settings()

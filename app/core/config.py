from __future__ import annotations

from pathlib import Path
from typing import List, Optional

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parents[2]  # .../FALL/app/core -> .../FALL


def _parse_csv(value: str) -> List[str]:
    value = (value or "").strip()
    if not value:
        return []
    return [x.strip() for x in value.split(",") if x.strip()]


class Settings(BaseSettings):
    """
    Prod/Dev ayarlarını env ile yönet.
    - Lokal: .env okunur
    - Prod: platform env vars verir (Render/Railway/Fly vb.)
    """

    model_config = SettingsConfigDict(
        env_file=str(BASE_DIR / ".env"),
        extra="ignore",
    )

    # ===== Environment =====
    environment: str = Field(default="dev", alias="ENVIRONMENT")  # dev / prod
    debug: bool = Field(default=False, alias="DEBUG")

    # ===== Storage paths =====
    # Render disk mount örn: STORAGE_DIR=/var/data
    storage_dir: Path = Field(default=BASE_DIR / "storage", alias="STORAGE_DIR")
    upload_dir: Optional[Path] = Field(default=None, alias="UPLOAD_DIR")

    # ===== DB URL (öncelik env) =====
    # Render disk kullanacaksan: DATABASE_URL=sqlite:////var/data/fall.db
    database_url: str = Field(
        default=f"sqlite:///{(BASE_DIR / 'storage' / 'fall.db').as_posix()}",
        alias="DATABASE_URL",
    )

    # ===== OpenAI =====
    openai_api_key: str = Field(default="", alias="OPENAI_API_KEY")
    openai_model: str = Field(default="gpt-4.1-mini", alias="OPENAI_MODEL")

    # ===== CORS =====
    # PROD örn: CORS_ORIGINS="https://lunaura.app,https://www.lunaura.app"
    cors_origins_raw: str = Field(default="*", alias="CORS_ORIGINS")

    # ===== IAP Verification =====
    # Dev için stub açılabilir, prod’da kapalı olmalı.
    allow_stub_iap: bool = Field(default=False, alias="ALLOW_STUB_IAP")

    # İleride gerçek doğrulama için (şimdilik boş kalsa da olur)
    google_play_package_name: str = Field(default="", alias="GOOGLE_PLAY_PACKAGE_NAME")
    apple_bundle_id: str = Field(default="", alias="APPLE_BUNDLE_ID")

    # Coffee rules
    min_photos: int = 3
    max_photos: int = 5

    @property
    def upload_dir_effective(self) -> Path:
        # UPLOAD_DIR verilmediyse storage/uploads kullan
        return self.upload_dir or (self.storage_dir / "uploads")

    @property
    def cors_origins(self) -> List[str]:
        raw = (self.cors_origins_raw or "").strip()
        if raw in {"", "*"}:
            return ["*"]
        return _parse_csv(raw)

    def ensure_dirs(self) -> None:
        # import-time side effect yerine startup’ta çağrılır
        self.storage_dir.mkdir(parents=True, exist_ok=True)
        self.upload_dir_effective.mkdir(parents=True, exist_ok=True)


settings = Settings()

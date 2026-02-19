# app/services/storage.py
from __future__ import annotations

import uuid
from pathlib import Path
from typing import List

from fastapi import UploadFile, HTTPException

from app.core.config import settings

# DB'de saklayacağımız sabit prefix (stabil path)
STABLE_ROOT = Path("storage") / "uploads"


def _safe_filename(original: str) -> str:
    original = (original or "").strip()
    ext = Path(original).suffix.lower()
    if ext not in [".jpg", ".jpeg", ".png", ".webp"]:
        ext = ".jpg"
    return f"{uuid.uuid4().hex}{ext}"


def _upload_base_dir() -> Path:
    """
    Gerçek disk base dir.
    config.py -> upload_dir_effective default: storage/uploads
    """
    base = Path(settings.upload_dir_effective)
    base.mkdir(parents=True, exist_ok=True)
    return base


def resolve_stable_path(stable_path: str) -> Path:
    """
    DB'deki stable path'i gerçek disk path'e çevirir.

    stable: storage/uploads/<rid>/<fn>.jpg
    disk  : <upload_dir_effective>/<rid>/<fn>.jpg  (default: storage/uploads/<rid>/<fn>.jpg)
    """
    p = Path((stable_path or "").replace("\\", "/"))
    base = _upload_base_dir()

    # "storage/uploads/<rid>/<fn>" formatını yakala
    try:
        parts = p.parts
        idx = parts.index("uploads")
        rid = parts[idx + 1]
        fn = parts[idx + 2]
        return base / rid / fn
    except Exception:
        # fallback: zaten relative/abs olabilir
        if p.is_absolute():
            return p
        return base / p


async def save_uploads(reading_id: str, files: List[UploadFile]) -> List[str]:
    """
    Dosyaları diske yazar ve DB için stable path listesi döndürür.
    DÖNÜŞ: ["storage/uploads/<reading_id>/<filename>.jpg", ...]
    """
    base = _upload_base_dir()
    dest_dir = base / reading_id
    dest_dir.mkdir(parents=True, exist_ok=True)

    saved: List[str] = []

    for f in files:
        filename = _safe_filename(f.filename)
        disk_path = dest_dir / filename

        data = await f.read()
        if not data or len(data) < 100:
            raise HTTPException(status_code=400, detail="Yüklenen görsel boş veya bozuk görünüyor.")

        disk_path.write_bytes(data)

        stable_path = (STABLE_ROOT / reading_id / filename).as_posix()
        saved.append(stable_path)

    return saved

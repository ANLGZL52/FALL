# app/services/storage.py
from __future__ import annotations

import os
import uuid
from pathlib import Path
from typing import List

from fastapi import UploadFile

from app.core.config import settings


def _safe_filename(original: str) -> str:
    # uzantıyı koru
    original = (original or "").strip()
    ext = Path(original).suffix.lower()
    if ext not in [".jpg", ".jpeg", ".png", ".webp"]:
        ext = ".jpg"
    return f"{uuid.uuid4().hex}{ext}"


async def save_uploads(reading_id: str, files: List[UploadFile]) -> List[str]:
    """
    Dosyaları diske yazar ve JSON/DB için string path listesi döndürür.
    DÖNÜŞ: ["storage/uploads/<reading_id>/<filename>.jpg", ...]
    """
    dest_dir = settings.upload_dir / reading_id
    dest_dir.mkdir(parents=True, exist_ok=True)

    saved_paths: List[str] = []

    for f in files:
        filename = _safe_filename(f.filename)
        dest_path = dest_dir / filename

        # dosyayı yaz
        data = await f.read()
        with open(dest_path, "wb") as out:
            out.write(data)

        # ✅ DB'ye relative path kaydediyoruz (proje kökünden)
        rel_path = os.path.relpath(dest_path, start=Path("."))
        rel_path = rel_path.replace("\\", "/")  # windows uyumu
        saved_paths.append(rel_path)

    return saved_paths

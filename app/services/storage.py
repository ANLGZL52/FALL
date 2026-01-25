# app/services/storage.py
from __future__ import annotations

import os
import uuid
from pathlib import Path
from typing import List

from fastapi import UploadFile

from app.core.config import settings


def _safe_filename(original: str) -> str:
    original = (original or "").strip()
    ext = Path(original).suffix.lower()
    if ext not in [".jpg", ".jpeg", ".png", ".webp"]:
        ext = ".jpg"
    return f"{uuid.uuid4().hex}{ext}"


async def save_uploads(reading_id: str, files: List[UploadFile]) -> List[str]:
    """
    Dosyaları diske yazar ve DB için relative path listesi döndürür.
    DÖNÜŞ: ["storage/uploads/<reading_id>/<filename>.jpg", ...]
    """
    # ✅ KRİTİK: upload_dir None olabilir → upload_dir_effective kullan
    dest_dir = settings.upload_dir_effective / reading_id
    dest_dir.mkdir(parents=True, exist_ok=True)

    saved_paths: List[str] = []

    for f in files:
        filename = _safe_filename(f.filename)
        dest_path = dest_dir / filename

        data = await f.read()
        with open(dest_path, "wb") as out:
            out.write(data)

        rel_path = os.path.relpath(dest_path, start=Path("."))
        rel_path = rel_path.replace("\\", "/")
        saved_paths.append(rel_path)

    return saved_paths

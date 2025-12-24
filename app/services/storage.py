# app/services/storage.py
import os
import uuid
from typing import List
from fastapi import UploadFile
from app.core.config import settings

async def save_uploads(reading_id: str, files: List[UploadFile]) -> List[str]:
    """
    Fotoğrafları diske kaydeder.
    Return: kaydedilen dosya path listesi (relative)
    """
    base_dir = os.path.join(settings.UPLOAD_DIR, reading_id)
    os.makedirs(base_dir, exist_ok=True)

    saved_paths: List[str] = []

    for f in files:
        ext = os.path.splitext(f.filename or "")[1].lower() or ".jpg"
        filename = f"{uuid.uuid4().hex}{ext}"
        path = os.path.join(base_dir, filename)

        content = await f.read()
        with open(path, "wb") as out:
            out.write(content)

        # relative path dönelim (windows uyumlu)
        saved_paths.append(path.replace("\\", "/"))

    return saved_paths

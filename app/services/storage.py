# app/services/storage.py
import os
import uuid
import shutil
from typing import List
from fastapi import UploadFile
from app.core.config import settings


async def save_uploads(reading_id: str, files: List[UploadFile]) -> List[str]:
    """
    Fotoğrafları diske kaydeder.
    Return: kaydedilen dosya path listesi (RELATIVE, forward slash)
    """
    base_dir = os.path.join(settings.UPLOAD_DIR, reading_id)
    os.makedirs(base_dir, exist_ok=True)

    saved_paths: List[str] = []

    for f in files:
        ext = os.path.splitext(f.filename or "")[1].lower() or ".jpg"
        filename = f"{uuid.uuid4().hex}{ext}"
        abs_path = os.path.join(base_dir, filename)

        content = await f.read()
        with open(abs_path, "wb") as out:
            out.write(content)

        # relative path: "storage/uploads/<id>/<file>.jpg"
        rel_path = abs_path.replace("\\", "/")
        saved_paths.append(rel_path)

    return saved_paths


def delete_reading_uploads(reading_id: str) -> None:
    """
    Completed sonrası disk şişmesin diye: ilgili klasörü sil.
    """
    folder = os.path.join(settings.UPLOAD_DIR, reading_id)
    if os.path.exists(folder):
        shutil.rmtree(folder, ignore_errors=True)

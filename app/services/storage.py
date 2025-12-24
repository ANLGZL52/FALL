# app/services/storage.py
import os
import uuid
import shutil
from pathlib import Path
from typing import List

from fastapi import UploadFile
from app.core.config import settings


def _project_root() -> Path:
    # app/services/storage.py -> app/services -> app -> PROJECT_ROOT
    return Path(__file__).resolve().parents[2]


async def save_uploads(reading_id: str, files: List[UploadFile]) -> List[str]:
    """
    Fotoğrafları diske kaydeder.

    ✅ Kayıt yeri: <project_root>/storage/uploads/<reading_id>/
    ✅ DB'ye dönen path: "storage/uploads/<reading_id>/<file>.jpg" (relative, forward slash)
    """
    project_root = _project_root()

    # settings.upload_base: absolute Path (config.py içinde çözülüyor)
    base_dir = Path(settings.upload_base) / reading_id
    base_dir.mkdir(parents=True, exist_ok=True)

    saved_paths: List[str] = []

    for f in files:
        ext = os.path.splitext(f.filename or "")[1].lower() or ".jpg"
        filename = f"{uuid.uuid4().hex}{ext}"
        abs_path = base_dir / filename

        content = await f.read()
        abs_path.write_bytes(content)

        # DB için relative path yaz
        rel_path = abs_path.relative_to(project_root).as_posix()
        saved_paths.append(rel_path)

    return saved_paths


def delete_reading_uploads(reading_id: str) -> None:
    """
    Completed sonrası disk şişmesin diye: ilgili klasörü sil.
    """
    folder = Path(settings.upload_base) / reading_id
    if folder.exists():
        shutil.rmtree(folder.as_posix(), ignore_errors=True)

# app/repositories/coffee_repo.py
from __future__ import annotations

import json
from typing import List, Optional
from datetime import datetime

from sqlmodel import Session

from app.models.coffee_db import CoffeeReadingDB


def _list_to_json(items: List[str]) -> str:
    return json.dumps(items, ensure_ascii=False)


def _list_from_json(s: str) -> List[str]:
    try:
        data = json.loads(s or "[]")
        return data if isinstance(data, list) else []
    except Exception:
        return []


def get_reading(session: Session, reading_id: str) -> Optional[CoffeeReadingDB]:
    return session.get(CoffeeReadingDB, reading_id)


def create_reading(session: Session, r: CoffeeReadingDB) -> CoffeeReadingDB:
    session.add(r)
    session.commit()
    session.refresh(r)
    return r


def update_reading(session: Session, r: CoffeeReadingDB) -> CoffeeReadingDB:
    r.updated_at = datetime.utcnow()
    session.add(r)
    session.commit()
    session.refresh(r)
    return r


def _get_images_json_field(r: CoffeeReadingDB) -> str:
    if hasattr(r, "images_json"):
        return getattr(r, "images_json") or "[]"
    if hasattr(r, "photos_json"):
        return getattr(r, "photos_json") or "[]"
    return "[]"


def _set_images_json_field(r: CoffeeReadingDB, value: str) -> None:
    if hasattr(r, "images_json"):
        setattr(r, "images_json", value)
        return
    if hasattr(r, "photos_json"):
        setattr(r, "photos_json", value)
        return
    raise AttributeError("Modelde images_json / photos_json alanı yok")


def set_photos(session: Session, reading_id: str, photos: List[str]) -> CoffeeReadingDB:
    r = get_reading(session, reading_id)
    if not r:
        raise KeyError("not_found")

    _set_images_json_field(r, _list_to_json(photos))

    # ✅ MOBİL SCHEMA İLE UYUMLU
    r.status = "photos_uploaded"
    return update_reading(session, r)


def list_photos(r: CoffeeReadingDB) -> List[str]:
    return _list_from_json(_get_images_json_field(r))


def set_status(
    session: Session,
    reading_id: str,
    status: str,
    *,
    comment: Optional[str] = None,
) -> CoffeeReadingDB:
    r = get_reading(session, reading_id)
    if not r:
        raise KeyError("not_found")

    r.status = status

    if comment is not None:
        if hasattr(r, "result_text"):
            r.result_text = comment
        elif hasattr(r, "comment"):
            r.comment = comment  # type: ignore[attr-defined]

    return update_reading(session, r)

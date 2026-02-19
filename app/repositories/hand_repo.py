# app/repositories/hand_repo.py
from __future__ import annotations

import json
from typing import List, Optional
from datetime import datetime

from sqlmodel import Session

from app.models.hand_db import HandReadingDB


def _list_to_json(items: List[str]) -> str:
    return json.dumps(items, ensure_ascii=False)


def _list_from_json(s: str) -> List[str]:
    try:
        data = json.loads(s or "[]")
        return data if isinstance(data, list) else []
    except Exception:
        return []


def get_reading(session: Session, reading_id: str) -> Optional[HandReadingDB]:
    return session.get(HandReadingDB, reading_id)


def create_reading(session: Session, r: HandReadingDB) -> HandReadingDB:
    session.add(r)
    session.commit()
    session.refresh(r)
    return r


def update_reading(session: Session, r: HandReadingDB) -> HandReadingDB:
    r.updated_at = datetime.utcnow()
    session.add(r)
    session.commit()
    session.refresh(r)
    return r


def set_photos(session: Session, reading_id: str, photos: List[str]) -> HandReadingDB:
    r = get_reading(session, reading_id)
    if not r:
        raise KeyError("not_found")

    r.images_json = _list_to_json(photos)
    r.status = "photos_uploaded"
    return update_reading(session, r)


def list_photos(r: HandReadingDB) -> List[str]:
    return _list_from_json(r.images_json or "[]")


def set_status(
    session: Session,
    reading_id: str,
    status: str,
    *,
    comment: Optional[str] = None,
) -> HandReadingDB:
    r = get_reading(session, reading_id)
    if not r:
        raise KeyError("not_found")

    r.status = status
    if comment is not None:
        r.result_text = comment

    return update_reading(session, r)

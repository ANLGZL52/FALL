# app/repositories/coffee_repo.py
import json
from typing import List, Optional
from sqlmodel import Session

from app.models.coffee_db import CoffeeReadingDB


def _photos_to_json(photos: List[str]) -> str:
    return json.dumps(photos, ensure_ascii=False)


def _photos_from_json(s: str) -> List[str]:
    try:
        return json.loads(s or "[]")
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
    session.add(r)
    session.commit()
    session.refresh(r)
    return r


def set_photos(session: Session, reading_id: str, photos: List[str]) -> CoffeeReadingDB:
    r = get_reading(session, reading_id)
    if not r:
        raise KeyError("not_found")
    r.photos_json = _photos_to_json(photos)
    r.status = "photos_uploaded"
    r.invalid_reason = None
    return update_reading(session, r)


def list_photos(r: CoffeeReadingDB) -> List[str]:
    return _photos_from_json(r.photos_json)


def set_status(
    session: Session,
    reading_id: str,
    status: str,
    *,
    invalid_reason: Optional[str] = None,
    comment: Optional[str] = None,
) -> CoffeeReadingDB:
    r = get_reading(session, reading_id)
    if not r:
        raise KeyError("not_found")
    r.status = status
    if invalid_reason is not None:
        r.invalid_reason = invalid_reason
    if comment is not None:
        r.comment = comment
    return update_reading(session, r)

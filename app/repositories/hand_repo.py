from __future__ import annotations
import json
from typing import List, Optional
from datetime import datetime

from sqlmodel import Session, select
from app.models.hand_db import HandReadingDB


def create_reading(session: Session, obj: HandReadingDB) -> HandReadingDB:
    session.add(obj)
    session.commit()
    session.refresh(obj)
    return obj


def get_reading(session: Session, reading_id: str) -> Optional[HandReadingDB]:
    return session.exec(select(HandReadingDB).where(HandReadingDB.id == reading_id)).first()


def update_reading(session: Session, obj: HandReadingDB) -> HandReadingDB:
    obj.updated_at = datetime.utcnow()
    session.add(obj)
    session.commit()
    session.refresh(obj)
    return obj


def set_photos(session: Session, reading_id: str, paths: List[str]) -> HandReadingDB:
    obj = get_reading(session, reading_id)
    assert obj is not None
    obj.images_json = json.dumps(paths, ensure_ascii=False)
    obj.updated_at = datetime.utcnow()
    return update_reading(session, obj)


def list_photos(obj: HandReadingDB) -> List[str]:
    try:
        return json.loads(obj.images_json or "[]")
    except Exception:
        return []


def set_status(session: Session, reading_id: str, status: str, comment: Optional[str] = None) -> HandReadingDB:
    obj = get_reading(session, reading_id)
    assert obj is not None
    obj.status = status
    if comment is not None:
        obj.result_text = comment
    obj.updated_at = datetime.utcnow()
    return update_reading(session, obj)

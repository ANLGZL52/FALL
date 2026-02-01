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
    stmt = select(HandReadingDB).where(HandReadingDB.id == reading_id)
    return session.exec(stmt).first()


def update_reading(session: Session, obj: HandReadingDB) -> HandReadingDB:
    obj.updated_at = datetime.utcnow()
    session.add(obj)
    session.commit()
    session.refresh(obj)
    return obj


def set_photos(session: Session, reading_id: str, paths: List[str]) -> HandReadingDB:
    obj = get_reading(session, reading_id)
    if not obj:
        raise KeyError("not_found")

    obj.images_json = json.dumps(paths, ensure_ascii=False)

    # ✅ upload sonrası status (tutarlı)
    # İstersen bu satırı route tarafında bırakabiliriz ama repo daha tutarlı olsun:
    if (obj.status or "").lower().strip() in ("pending_payment", "created", ""):
        obj.status = "images_uploaded"

    return update_reading(session, obj)


def list_photos(obj: HandReadingDB) -> List[str]:
    try:
        data = json.loads(obj.images_json or "[]")
        return data if isinstance(data, list) else []
    except Exception:
        return []


def set_status(
    session: Session,
    reading_id: str,
    status: str,
    comment: Optional[str] = None,
) -> HandReadingDB:
    obj = get_reading(session, reading_id)
    if not obj:
        raise KeyError("not_found")

    obj.status = status
    if comment is not None:
        obj.result_text = comment

    return update_reading(session, obj)

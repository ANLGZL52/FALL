from __future__ import annotations

from typing import Optional, List
from datetime import datetime
from sqlmodel import Session, select

from app.models.tarot_db import TarotReadingDB


def create_reading(session: Session, obj: TarotReadingDB) -> TarotReadingDB:
    session.add(obj)
    session.commit()
    session.refresh(obj)
    return obj


def get_reading(session: Session, reading_id: str) -> Optional[TarotReadingDB]:
    return session.exec(select(TarotReadingDB).where(TarotReadingDB.id == reading_id)).first()


def update_reading(session: Session, obj: TarotReadingDB) -> TarotReadingDB:
    obj.updated_at = datetime.utcnow()
    session.add(obj)
    session.commit()
    session.refresh(obj)
    return obj


def set_cards(session: Session, reading_id: str, cards: List[str]) -> TarotReadingDB:
    obj = get_reading(session, reading_id)
    assert obj is not None
    obj.set_cards(cards)
    return update_reading(session, obj)


def set_status(
    session: Session,
    reading_id: str,
    status: str,
    result_text: Optional[str] = None,
) -> TarotReadingDB:
    obj = get_reading(session, reading_id)
    assert obj is not None
    obj.status = status
    if result_text is not None:
        obj.result_text = result_text
    return update_reading(session, obj)

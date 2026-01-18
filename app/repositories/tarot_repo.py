from __future__ import annotations

from datetime import datetime
from typing import Optional, List

from sqlmodel import Session, select
from sqlalchemy import update

from app.models.tarot_db import TarotReadingDB


def create_reading(session: Session, obj: TarotReadingDB) -> TarotReadingDB:
    session.add(obj)
    session.commit()
    session.refresh(obj)
    return obj


def get_reading(session: Session, reading_id: str) -> Optional[TarotReadingDB]:
    stmt = select(TarotReadingDB).where(TarotReadingDB.id == reading_id)
    return session.exec(stmt).first()


def update_reading(session: Session, obj: TarotReadingDB) -> TarotReadingDB:
    obj.updated_at = datetime.utcnow()
    session.add(obj)
    session.commit()
    session.refresh(obj)
    return obj


def set_cards(session: Session, reading_id: str, cards: List[str]) -> TarotReadingDB:
    r = get_reading(session, reading_id)
    if not r:
        raise ValueError("reading_not_found")

    r.set_cards(cards)
    r.status = "selected"
    r.updated_at = datetime.utcnow()

    session.add(r)
    session.commit()
    session.refresh(r)
    return r


def set_status(
    session: Session,
    reading_id: str,
    status: str,
    result_text: Optional[str] = None,
) -> TarotReadingDB:
    r = get_reading(session, reading_id)
    if not r:
        raise ValueError("reading_not_found")

    r.status = status
    if result_text is not None:
        r.result_text = result_text

    r.updated_at = datetime.utcnow()

    session.add(r)
    session.commit()
    session.refresh(r)
    return r


def claim_processing(session: Session, reading_id: str) -> bool:
    """
    ✅ Atomic "processing lock"
    Aynı reading için birden fazla worker/thread generate başlatmasın.

    - Zaten completed ise dokunmaz.
    - Zaten processing ise dokunmaz.
    - Paid/Selected gibi durumlarda processing'e geçirir.
    """
    now = datetime.utcnow()

    stmt = (
        update(TarotReadingDB)
        .where(TarotReadingDB.id == reading_id)
        .where(TarotReadingDB.status != "processing")
        .where(TarotReadingDB.status != "completed")
        .values(status="processing", updated_at=now)
    )

    res = session.exec(stmt)
    session.commit()

    # SQLAlchemy rowcount bazı driverlarda None dönebilir; gene de best-effort
    try:
        return bool(res.rowcount and res.rowcount > 0)
    except Exception:
        # Fallback: tekrar okuyup kontrol et
        r = get_reading(session, reading_id)
        return bool(r and r.status == "processing")

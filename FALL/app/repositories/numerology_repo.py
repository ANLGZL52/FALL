from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import uuid4

from sqlmodel import Session, select

from app.models.numerology_db import NumerologyReadingDB


def _dump(obj: NumerologyReadingDB) -> dict:
    # SQLModel/Pydantic v1-v2 uyumu
    if hasattr(obj, "model_dump"):
        return obj.model_dump()
    return obj.dict()


# -------------------------
# Low-level funcs
# -------------------------
def create_reading(session: Session, obj: NumerologyReadingDB) -> NumerologyReadingDB:
    session.add(obj)
    session.commit()
    session.refresh(obj)
    return obj


def get_reading(session: Session, reading_id: str) -> Optional[NumerologyReadingDB]:
    stmt = select(NumerologyReadingDB).where(NumerologyReadingDB.id == reading_id)
    return session.exec(stmt).first()


def update_reading(session: Session, obj: NumerologyReadingDB) -> NumerologyReadingDB:
    obj.updated_at = datetime.utcnow()
    session.add(obj)
    session.commit()
    session.refresh(obj)
    return obj


def mark_paid_low(session: Session, reading_id: str, payment_ref: Optional[str]) -> NumerologyReadingDB:
    obj = get_reading(session, reading_id)
    if not obj:
        raise ValueError("Reading not found")

    # ✅ idempotent
    obj.is_paid = True
    obj.payment_ref = payment_ref
    obj.status = "paid"
    return update_reading(session, obj)


def set_status_low(session: Session, reading_id: str, status: str) -> NumerologyReadingDB:
    """
    ✅ Standard: started / paid / processing / completed
    (done yerine completed kullanıyoruz; diğer modüllerle aynı olsun)
    """
    st = (status or "").lower().strip()
    if st not in ("started", "paid", "processing", "completed"):
        raise ValueError(f"Invalid status: {status}")

    obj = get_reading(session, reading_id)
    if not obj:
        raise ValueError("Reading not found")

    obj.status = st
    return update_reading(session, obj)


def set_result_low(session: Session, reading_id: str, result_text: str) -> NumerologyReadingDB:
    obj = get_reading(session, reading_id)
    if not obj:
        raise ValueError("Reading not found")

    obj.result_text = result_text
    obj.status = "completed"  # ✅ standard
    return update_reading(session, obj)


# -------------------------
# High-level Repo (routes ile uyumlu)
# -------------------------
class NumerologyRepo:
    def create(
        self,
        *,
        session: Session,
        name: str,
        birth_date: str,
        topic: str,
        question: Optional[str],
        device_id: Optional[str] = None,  # ✅ NEW
    ) -> dict:
        obj = NumerologyReadingDB(
            id=uuid4().hex,
            topic=topic,
            question=question,
            name=name,
            birth_date=birth_date,
            status="started",
            is_paid=False,
            payment_ref=None,
            result_text=None,
        )

        # ✅ device_id ilişkilendir (model patch’iyle kolon eklenecek)
        try:
            setattr(obj, "device_id", (device_id or "").strip() or None)
        except Exception:
            pass

        created = create_reading(session, obj)
        return _dump(created)

    def get(self, *, session: Session, reading_id: str) -> Optional[dict]:
        obj = get_reading(session, reading_id)
        return _dump(obj) if obj else None

    def mark_paid(self, *, session: Session, reading_id: str, payment_ref: Optional[str]) -> Optional[dict]:
        try:
            obj = mark_paid_low(session, reading_id, payment_ref)
            return _dump(obj)
        except ValueError:
            return None

    def set_status(self, *, session: Session, reading_id: str, status: str) -> Optional[dict]:
        try:
            obj = set_status_low(session, reading_id, status)
            return _dump(obj)
        except ValueError:
            return None

    def set_result(self, *, session: Session, reading_id: str, result_text: str) -> Optional[dict]:
        try:
            obj = set_result_low(session, reading_id, result_text)
            return _dump(obj)
        except ValueError:
            return None


numerology_repo = NumerologyRepo()

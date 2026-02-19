from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlmodel import Session, select

from app.models.personality_db import PersonalityReadingDB


def _dump(obj: PersonalityReadingDB) -> dict:
    return {
        "id": obj.id,
        "device_id": getattr(obj, "device_id", None),
        "name": obj.name,
        "birth_date": obj.birth_date,
        "birth_time": obj.birth_time,
        "birth_city": obj.birth_city,
        "birth_country": obj.birth_country,
        "topic": obj.topic,
        "question": obj.question,
        "status": obj.status,
        "result_text": obj.result_text,
        "is_paid": obj.is_paid,
        "payment_ref": obj.payment_ref,
        "rating": obj.rating,
        "created_at": obj.created_at,
        "updated_at": obj.updated_at,
    }


def _get(session: Session, reading_id: str) -> Optional[PersonalityReadingDB]:
    stmt = select(PersonalityReadingDB).where(PersonalityReadingDB.id == reading_id)
    return session.exec(stmt).first()


def _commit(session: Session, obj: PersonalityReadingDB) -> PersonalityReadingDB:
    obj.updated_at = datetime.utcnow()
    session.add(obj)
    session.commit()
    session.refresh(obj)
    return obj


class PersonalityRepo:
    def create(
        self,
        *,
        session: Session,
        reading_id: str,
        name: str,
        birth_date: str,
        birth_time: Optional[str],
        birth_city: str,
        birth_country: str,
        topic: str,
        question: Optional[str],
        device_id: Optional[str] = None,
    ) -> dict:
        now = datetime.utcnow()

        obj = PersonalityReadingDB(
            id=reading_id,
            device_id=device_id,
            name=name,
            birth_date=birth_date,
            birth_time=birth_time,
            birth_city=birth_city,
            birth_country=(birth_country or "TR"),
            topic=(topic or "genel"),
            question=question,
            status="created",
            is_paid=False,
            created_at=now,
            updated_at=now,
        )
        session.add(obj)
        session.commit()
        session.refresh(obj)
        return _dump(obj)

    def get(self, *, session: Session, reading_id: str) -> Optional[dict]:
        obj = _get(session, reading_id)
        return _dump(obj) if obj else None

    def mark_paid(
        self,
        *,
        session: Session,
        reading_id: str,
        payment_ref: Optional[str],
    ) -> Optional[dict]:
        obj = _get(session, reading_id)
        if not obj:
            return None
        obj.is_paid = True
        obj.payment_ref = payment_ref
        obj.status = "paid"
        return _dump(_commit(session, obj))

    def set_status(self, *, session: Session, reading_id: str, status: str) -> Optional[dict]:
        obj = _get(session, reading_id)
        if not obj:
            return None
        obj.status = status
        return _dump(_commit(session, obj))

    def set_result(self, *, session: Session, reading_id: str, result_text: str) -> Optional[dict]:
        obj = _get(session, reading_id)
        if not obj:
            return None
        obj.result_text = result_text
        obj.status = "done"  # ✅ done kullanıyoruz (generate tarafı done/completed ikisini de kabul ediyor)
        return _dump(_commit(session, obj))

    def set_rating(self, *, session: Session, reading_id: str, rating: int) -> Optional[dict]:
        obj = _get(session, reading_id)
        if not obj:
            return None
        obj.rating = rating
        return _dump(_commit(session, obj))


personality_repo = PersonalityRepo()

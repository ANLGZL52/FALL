# app/services/coffee_service.py
from datetime import datetime
from typing import Dict, List, Optional
from uuid import uuid4

from app.schemas.coffee import CoffeeReading, CoffeeStartRequest


# Geçici in-memory "DB"
_COFFER_DB: Dict[str, CoffeeReading] = {}


def start_coffee_reading(
    payload: CoffeeStartRequest,
    user_id: Optional[str] = None
) -> CoffeeReading:
    reading_id = str(uuid4())
    reading = CoffeeReading(
        id=reading_id,
        user_id=user_id,
        topic=payload.topic,
        question=payload.question,
        relationship_status=payload.relationship_status,
        big_decision=payload.big_decision,
        name=payload.name,
        age=payload.age,
        status="pending_payment",
        created_at=datetime.utcnow(),
    )
    _COFFER_DB[reading_id] = reading
    return reading


def attach_photos(reading_id: str, photo_paths: List[str]) -> CoffeeReading:
    reading = _COFFER_DB.get(reading_id)
    if not reading:
        raise KeyError("not found")

    new_photos = reading.photos + photo_paths
    updated = reading.model_copy(update={"photos": new_photos})
    _COFFER_DB[reading_id] = updated
    return updated


def mark_paid(reading_id: str, payment_ref: Optional[str] = None) -> CoffeeReading:
    reading = _COFFER_DB.get(reading_id)
    if not reading:
        raise KeyError("not found")
    updated = reading.model_copy(
        update={
            "status": "paid",
            "payment_ref": payment_ref,
        }
    )
    _COFFER_DB[reading_id] = updated
    return updated


def set_comment_and_ready(reading_id: str, comment: str) -> CoffeeReading:
    reading = _COFFER_DB.get(reading_id)
    if not reading:
        raise KeyError("not found")
    updated = reading.model_copy(
        update={
            "status": "ready",
            "comment": comment,
        }
    )
    _COFFER_DB[reading_id] = updated
    return updated


def rate_reading(reading_id: str, rating: int) -> CoffeeReading:
    reading = _COFFER_DB.get(reading_id)
    if not reading:
        raise KeyError("not found")
    updated = reading.model_copy(update={"rating": rating})
    _COFFER_DB[reading_id] = updated
    return updated


def get_reading(reading_id: str) -> Optional[CoffeeReading]:
    return _COFFER_DB.get(reading_id)


def list_readings(user_id: Optional[str] = None) -> List[CoffeeReading]:
    values = list(_COFFER_DB.values())
    if user_id is not None:
        values = [r for r in values if r.user_id == user_id]
    # Yeni en üstte
    values.sort(key=lambda r: r.created_at, reverse=True)
    return values

# app/models/coffee_db.py
from datetime import datetime
from typing import Optional

from sqlmodel import SQLModel, Field

class CoffeeReadingDB(SQLModel, table=True):
    __tablename__ = "coffee_readings"

    id: str = Field(primary_key=True, index=True)

    # form bilgileri
    topic: str
    question: str
    relationship_status: Optional[str] = None
    big_decision: Optional[str] = None
    name: str
    age: Optional[int] = None

    # storage
    photos_json: str = "[]"          # json string (list[str])
    status: str = "pending_payment"  # pending_payment, photos_uploaded, invalid_photos, paid, processing, completed
    comment: Optional[str] = None
    rating: Optional[int] = None

    # ödeme
    is_paid: bool = False
    payment_ref: Optional[str] = None

    # validasyon
    invalid_reason: Optional[str] = None

    created_at: datetime = Field(default_factory=datetime.utcnow)

# app/models/hand_db.py
from __future__ import annotations

from typing import Optional
from datetime import datetime
from sqlmodel import SQLModel, Field


class HandReadingDB(SQLModel, table=True):
    __tablename__ = "hand_readings"

    id: str = Field(primary_key=True, index=True)

    topic: str
    question: str
    name: str
    age: Optional[int] = None

    dominant_hand: Optional[str] = None   # "right" / "left"
    photo_hand: Optional[str] = None      # "right" / "left"

    relationship_status: Optional[str] = None
    big_decision: Optional[str] = None

    images_json: str = "[]"
    result_text: Optional[str] = None

    status: str = "pending_payment"
    is_paid: bool = False
    payment_ref: Optional[str] = None

    rating: Optional[int] = None

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

# app/models/personality_db.py
from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlmodel import SQLModel, Field


class PersonalityReadingDB(SQLModel, table=True):
    __tablename__ = "personality_readings"

    # PK
    id: str = Field(primary_key=True, index=True)

    # User inputs
    name: str
    birth_date: str  # YYYY-MM-DD
    birth_time: Optional[str] = Field(default=None)  # HH:MM (opsiyonel)
    birth_city: str
    birth_country: str = Field(default="TR")

    # Reading context
    topic: str = Field(default="genel", index=True)
    question: Optional[str] = Field(default=None)

    # Lifecycle
    status: str = Field(default="started", index=True)  # started/paid/processing/completed
    result_text: Optional[str] = Field(default=None)

    # Paid flow
    is_paid: bool = Field(default=False, index=True)
    payment_ref: Optional[str] = Field(default=None)

    # Feedback
    rating: Optional[int] = Field(default=None)

    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

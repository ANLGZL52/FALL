# app/models/numerology_db.py
from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlmodel import SQLModel, Field


class NumerologyReadingDB(SQLModel, table=True):
    __tablename__ = "numerology_readings"

    id: str = Field(primary_key=True, index=True)

    topic: str = Field(index=True)
    question: Optional[str] = Field(default=None)

    name: str
    birth_date: str  # YYYY-MM-DD

    status: str = Field(default="started", index=True)  # started/paid/processing/completed
    result_text: Optional[str] = Field(default=None)

    rating: Optional[int] = Field(default=None)

    is_paid: bool = Field(default=False, index=True)
    payment_ref: Optional[str] = Field(default=None)

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

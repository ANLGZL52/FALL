# app/models/birthchart_db.py
from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import uuid4

from sqlmodel import SQLModel, Field


class BirthChartReadingDB(SQLModel, table=True):
    __tablename__ = "birthchart_readings"

    # ✅ PK default ver (Postgres insert için şart)
    id: str = Field(default_factory=lambda: str(uuid4()), primary_key=True, index=True)

    topic: str = Field(default="genel", index=True)
    question: Optional[str] = Field(default=None)

    name: str
    birth_date: str  # YYYY-MM-DD
    birth_time: Optional[str] = Field(default=None)  # HH:MM
    birth_city: str
    birth_country: str = Field(default="TR")

    status: str = Field(default="started", index=True)  # started/paid/processing/completed
    result_text: Optional[str] = Field(default=None)

    rating: Optional[int] = Field(default=None)

    is_paid: bool = Field(default=False, index=True)
    payment_ref: Optional[str] = Field(default=None)

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

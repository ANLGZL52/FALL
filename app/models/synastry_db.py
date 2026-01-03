from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlmodel import SQLModel, Field


class SynastryReadingDB(SQLModel, table=True):
    __tablename__ = "synastry_readings"

    id: Optional[int] = Field(default=None, primary_key=True)

    reading_id: str = Field(index=True, unique=True)

    # Partner A
    name_a: str
    birth_date_a: str  # YYYY-MM-DD
    birth_time_a: Optional[str] = None  # HH:MM
    birth_city_a: str
    birth_country_a: str = "TR"

    # Partner B
    name_b: str
    birth_date_b: str  # YYYY-MM-DD
    birth_time_b: Optional[str] = None  # HH:MM
    birth_city_b: str
    birth_country_b: str = "TR"

    topic: str = "genel"
    question: Optional[str] = None

    is_paid: bool = False
    payment_ref: Optional[str] = None

    status: str = "started"  # started / paid / processing / done

    rating: Optional[int] = None
    result_text: Optional[str] = None

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

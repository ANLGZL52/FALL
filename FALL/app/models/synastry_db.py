from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import uuid4

from sqlmodel import SQLModel, Field


class SynastryReadingDB(SQLModel, table=True):
    __tablename__ = "synastry_readings"

    id: str = Field(
        default_factory=lambda: str(uuid4()),
        primary_key=True,
        index=True,
    )

    device_id: Optional[str] = Field(
        default=None,
        index=True,
        description="Mobil cihaz kimliği (X-Device-Id)",
    )

    # Partner A
    name_a: str = Field(default="")
    birth_date_a: str = Field(default="")
    birth_time_a: Optional[str] = Field(default=None)
    birth_city_a: str = Field(default="")
    birth_country_a: str = Field(default="TR")

    # Partner B
    name_b: str = Field(default="")
    birth_date_b: str = Field(default="")
    birth_time_b: Optional[str] = Field(default=None)
    birth_city_b: str = Field(default="")
    birth_country_b: str = Field(default="TR")

    topic: str = Field(default="genel", index=True)
    question: Optional[str] = Field(default=None)

    is_paid: bool = Field(default=False, index=True)
    payment_ref: Optional[str] = Field(default=None, index=True)

    status: str = Field(default="started", index=True)

    result_text: Optional[str] = Field(default=None)
    rating: Optional[int] = Field(default=None)

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import uuid4

from sqlmodel import SQLModel, Field


class BirthChartReadingDB(SQLModel, table=True):
    __tablename__ = "birthchart_readings"

    # ✅ PK (uuid – tüm modüllerle standart)
    id: str = Field(
        default_factory=lambda: str(uuid4()),
        primary_key=True,
        index=True,
    )

    # ✅ CİHAZ BAZLI SAHİPLİK (Profil için KRİTİK)
    device_id: Optional[str] = Field(
        default=None,
        index=True,
        description="Mobil cihaz kimliği (X-Device-Id)",
    )

    # Form alanları
    topic: str = Field(default="genel", index=True)
    question: Optional[str] = Field(default=None)

    name: str
    birth_date: str  # YYYY-MM-DD
    birth_time: Optional[str] = Field(default=None)  # HH:MM
    birth_city: str
    birth_country: str = Field(default="TR")

    # Durum
    # started / paid / processing / completed
    status: str = Field(
        default="started",
        index=True,
    )

    # Sonuç
    result_text: Optional[str] = Field(default=None)

    # Puan
    rating: Optional[int] = Field(default=None)

    # Ödeme
    is_paid: bool = Field(default=False, index=True)
    payment_ref: Optional[str] = Field(default=None)

    # Zaman
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

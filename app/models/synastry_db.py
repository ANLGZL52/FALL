from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import uuid4

from sqlmodel import SQLModel, Field


class SynastryReadingDB(SQLModel, table=True):
    __tablename__ = "synastry_readings"

    # ✅ PK (uuid – tüm sistemle standart)
    id: str = Field(
        default_factory=lambda: str(uuid4()),
        primary_key=True,
        index=True,
    )

    # ✅ Cihaz bazlı sahiplik (Profil için KRİTİK)
    device_id: Optional[str] = Field(
        default=None,
        index=True,
        description="Mobil cihaz kimliği (X-Device-Id)",
    )

    # Partner A
    name_a: str
    birth_date_a: str  # YYYY-MM-DD
    birth_time_a: Optional[str] = Field(default=None)  # HH:MM
    birth_city_a: str
    birth_country_a: str = Field(default="TR")

    # Partner B
    name_b: str
    birth_date_b: str  # YYYY-MM-DD
    birth_time_b: Optional[str] = Field(default=None)  # HH:MM
    birth_city_b: str
    birth_country_b: str = Field(default="TR")

    # İçerik
    topic: str = Field(default="genel", index=True)
    question: Optional[str] = Field(default=None)

    # Ödeme
    is_paid: bool = Field(default=False, index=True)
    payment_ref: Optional[str] = Field(default=None)

    # Durum
    # started / paid / processing / completed
    status: str = Field(default="started", index=True)

    # Sonuç
    result_text: Optional[str] = Field(default=None)

    # Puan
    rating: Optional[int] = Field(default=None)

    # Zaman
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

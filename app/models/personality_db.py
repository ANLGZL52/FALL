from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import uuid4

from sqlmodel import SQLModel, Field


class PersonalityReadingDB(SQLModel, table=True):
    __tablename__ = "personality_readings"

    # ✅ PK (uuid – tüm sistemle uyumlu)
    id: str = Field(
        default_factory=lambda: str(uuid4()),
        primary_key=True,
        index=True,
    )

    # ✅ CİHAZ SAHİPLİĞİ (Profil için KRİTİK)
    device_id: Optional[str] = Field(
        default=None,
        index=True,
        description="Mobil cihaz kimliği (X-Device-Id)",
    )

    # Kullanıcı bilgileri
    name: str
    birth_date: str  # YYYY-MM-DD
    birth_time: Optional[str] = Field(default=None)  # HH:MM
    birth_city: str
    birth_country: str = Field(default="TR")

    # İçerik
    topic: str = Field(default="genel", index=True)
    question: Optional[str] = Field(default=None)

    # Durum
    # started / paid / processing / completed
    status: str = Field(default="started", index=True)

    # Sonuç
    result_text: Optional[str] = Field(default=None)

    # Ödeme
    is_paid: bool = Field(default=False, index=True)
    payment_ref: Optional[str] = Field(default=None)

    # Puanlama
    rating: Optional[int] = Field(default=None)

    # Zaman
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

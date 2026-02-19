from __future__ import annotations

from typing import Optional
from datetime import datetime
from uuid import uuid4

from sqlmodel import SQLModel, Field


class HandReadingDB(SQLModel, table=True):
    __tablename__ = "hand_readings"

    # ✅ PK: default uuid (tüm modüllerle tutarlı)
    id: str = Field(
        default_factory=lambda: str(uuid4()),
        primary_key=True,
        index=True,
    )

    # ✅ Cihaz bazlı sahiplik (profilin temeli)
    device_id: Optional[str] = Field(
        default=None,
        index=True,
        description="Mobil cihaz kimliği (X-Device-Id)",
    )

    # Kullanıcı inputları
    topic: str = Field(default="Genel", index=True)
    question: str = Field(default="")
    name: str = Field(default="Misafir", index=True)
    age: Optional[int] = Field(default=None)

    # El bilgileri
    dominant_hand: Optional[str] = Field(default=None)   # "right" / "left"
    photo_hand: Optional[str] = Field(default=None)      # "right" / "left"

    relationship_status: Optional[str] = Field(default=None)
    big_decision: Optional[str] = Field(default=None)

    # Foto & sonuç
    images_json: str = Field(default="[]")
    result_text: Optional[str] = Field(default=None)

    # süreç
    status: str = Field(
        default="pending_payment",
        index=True,
        description="pending_payment / images_uploaded / paid / processing / completed",
    )
    is_paid: bool = Field(default=False)
    payment_ref: Optional[str] = Field(default=None)

    # rating
    rating: Optional[int] = Field(default=None)

    # timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

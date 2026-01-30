from __future__ import annotations

from typing import Optional
from datetime import datetime
from sqlmodel import SQLModel, Field


class HandReadingDB(SQLModel, table=True):
    __tablename__ = "hand_readings"

    # ✅ Primary key
    id: str = Field(primary_key=True, index=True)

    # ✅ Cihaz bazlı sahiplik (profilin temeli)
    device_id: Optional[str] = Field(
        default=None,
        index=True,
        description="Mobil cihaz kimliği (X-Device-Id)",
    )

    # Kullanıcı inputları
    topic: str
    question: str
    name: str
    age: Optional[int] = None

    # El bilgileri
    dominant_hand: Optional[str] = None   # "right" / "left"
    photo_hand: Optional[str] = None      # "right" / "left"

    relationship_status: Optional[str] = None
    big_decision: Optional[str] = None

    # Foto & sonuç
    images_json: str = Field(default="[]")
    result_text: Optional[str] = None

    # süreç
    status: str = Field(
        default="pending_payment",
        index=True,
        description="pending_payment / paid / processing / completed",
    )
    is_paid: bool = Field(default=False)
    payment_ref: Optional[str] = None

    # rating
    rating: Optional[int] = None

    # timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

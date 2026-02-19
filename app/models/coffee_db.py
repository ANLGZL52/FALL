from __future__ import annotations

from typing import Optional
from datetime import datetime
from uuid import uuid4

from sqlmodel import SQLModel, Field


class CoffeeReadingDB(SQLModel, table=True):
    __tablename__ = "coffee_readings"

    # ✅ PK: default uuid
    id: str = Field(
        default_factory=lambda: str(uuid4()),
        primary_key=True,
        index=True,
    )

    # ✅ Cihaz bazlı sahiplik (profilin TEMELİ)
    device_id: Optional[str] = Field(
        default=None,
        index=True,
        description="Mobil cihaz kimliği (X-Device-Id)",
    )

    # Kullanıcı inputları
    topic: str = Field(default="Genel", index=True)
    question: str = Field(default="")

    name: str = Field(default="", index=True)
    age: Optional[int] = Field(default=None)

    # Foto & sonuç
    images_json: str = Field(
        default="[]",
        description="Yüklenen foto path'lerinin JSON listesi",
    )
    result_text: Optional[str] = Field(default=None)

    # süreç
    status: str = Field(
        default="created",
        index=True,
        description="created / images_uploaded / paid / done",
    )
    is_paid: bool = Field(default=False)
    payment_ref: Optional[str] = Field(default=None)

    # rating
    rating: Optional[int] = Field(default=None)

    # timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

from __future__ import annotations

from datetime import datetime
from typing import Optional, List
import json
import uuid

from sqlmodel import SQLModel, Field


class TarotReadingDB(SQLModel, table=True):
    __tablename__ = "tarot_readings"

    # ✅ UUID string PK
    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
    )

    # ✅ device ownership
    device_id: Optional[str] = Field(
        default=None,
        index=True,
        description="Mobil cihaz kimliği (X-Device-Id)",
    )

    # kullanıcı
    name: str = Field(default="Misafir", max_length=80)
    age: Optional[int] = Field(default=None)

    # form
    topic: str = Field(default="", max_length=120)
    question: str = Field(default="", max_length=500)

    # three / six / twelve
    spread_type: str = Field(default="three", max_length=20)

    # cards json
    cards_json: str = Field(default="[]", description="Seçilen kartların JSON listesi")

    # ödeme
    is_paid: bool = Field(default=False, index=True)
    payment_ref: Optional[str] = Field(default=None, index=True)

    # status
    status: str = Field(default="pending_payment", max_length=30, index=True)

    # sonuç / rating
    result_text: Optional[str] = Field(default=None)
    rating: Optional[int] = Field(default=None)

    # timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow, index=True)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    def get_cards(self) -> List[str]:
        try:
            data = json.loads(self.cards_json or "[]")
            return data if isinstance(data, list) else []
        except Exception:
            return []

    def set_cards(self, cards: List[str]) -> None:
        self.cards_json = json.dumps(cards or [], ensure_ascii=False)

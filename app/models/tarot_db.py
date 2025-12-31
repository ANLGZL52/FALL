from __future__ import annotations

from datetime import datetime
from typing import Optional, List
import json
import uuid

from sqlmodel import SQLModel, Field


class TarotReadingDB(SQLModel, table=True):
    __tablename__ = "tarot_readings"

    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True, index=True)

    # kullanıcı bilgileri
    name: str = Field(default="Misafir", max_length=80)
    age: Optional[int] = Field(default=None)

    # tarot form
    topic: str = Field(default="", max_length=120)
    question: str = Field(default="", max_length=500)

    # ✅ three/six/twelve (senin Flutter ile uyumlu)
    spread_type: str = Field(default="three", max_length=20)

    # ✅ kartlar json string olarak tutulur
    cards_json: str = Field(default="[]")

    # ödeme + durum
    is_paid: bool = Field(default=False)
    payment_ref: Optional[str] = Field(default=None)   # ✅ route kullanıyor
    status: str = Field(default="started", max_length=20)  # started/selected/processing/completed

    # çıktı
    result_text: Optional[str] = Field(default=None)

    # ✅ puan (route kullanıyor)
    rating: Optional[int] = Field(default=None)

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    # helpers
    def get_cards(self) -> List[str]:
        try:
            data = json.loads(self.cards_json or "[]")
            return data if isinstance(data, list) else []
        except Exception:
            return []

    def set_cards(self, cards: List[str]) -> None:
        self.cards_json = json.dumps(cards, ensure_ascii=False)

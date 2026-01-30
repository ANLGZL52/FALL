from __future__ import annotations

from datetime import datetime
from typing import Optional, List
import json
import uuid

from sqlmodel import SQLModel, Field


class TarotReadingDB(SQLModel, table=True):
    __tablename__ = "tarot_readings"

    # ✅ PK
    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
    )

    # ✅ CİHAZ BAZLI SAHİPLİK (PROFİLİN BEL KEMİĞİ)
    device_id: Optional[str] = Field(
        default=None,
        index=True,
        description="Mobil cihaz kimliği (X-Device-Id)",
    )

    # Kullanıcı bilgileri
    name: str = Field(default="Misafir", max_length=80)
    age: Optional[int] = Field(default=None)

    # Tarot form
    topic: str = Field(default="", max_length=120)
    question: str = Field(default="", max_length=500)

    # Açılım tipi: three / six / twelve
    spread_type: str = Field(default="three", max_length=20)

    # Kartlar (json string)
    cards_json: str = Field(
        default="[]",
        description="Seçilen kartların JSON listesi",
    )

    # Ödeme
    is_paid: bool = Field(default=False, index=True)  # ✅ (opsiyonel) filtreleme hızlanır
    payment_ref: Optional[str] = Field(default=None)

    # Durum: pending_payment / selected / paid / processing / completed
    status: str = Field(
        default="pending_payment",
        max_length=30,
        index=True,
    )

    # Çıktı
    result_text: Optional[str] = Field(default=None)

    # Puan
    rating: Optional[int] = Field(default=None)

    # Zaman
    created_at: datetime = Field(default_factory=datetime.utcnow, index=True)  # ✅ (opsiyonel) listelerken hız
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    # --------------------
    # Helpers
    # --------------------
    def get_cards(self) -> List[str]:
        try:
            data = json.loads(self.cards_json or "[]")
            return data if isinstance(data, list) else []
        except Exception:
            return []

    def set_cards(self, cards: List[str]) -> None:
        self.cards_json = json.dumps(cards, ensure_ascii=False)

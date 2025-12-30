from __future__ import annotations

import json
from typing import Optional, List
from datetime import datetime
from sqlmodel import SQLModel, Field


class TarotReadingDB(SQLModel, table=True):
    __tablename__ = "tarot_readings"

    id: str = Field(primary_key=True, index=True)

    topic: str
    question: str
    name: str
    age: Optional[int] = None

    spread_type: str = "three"  # "one" | "three" | "five"
    selected_cards_json: str = "[]"

    result_text: Optional[str] = None

    status: str = "pending_payment"  # pending_payment | paid | processing | completed
    is_paid: bool = False
    payment_ref: Optional[str] = None

    rating: Optional[int] = None

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    # yardımcılar
    def set_cards(self, cards: List[str]) -> None:
        self.selected_cards_json = json.dumps(cards, ensure_ascii=False)

    def get_cards(self) -> List[str]:
        try:
            return json.loads(self.selected_cards_json or "[]")
        except Exception:
            return []

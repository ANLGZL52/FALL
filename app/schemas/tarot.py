from __future__ import annotations

from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel


class TarotStartRequest(BaseModel):
    name: str
    age: Optional[int] = None
    topic: str
    question: str
    spread_type: str  # "one" | "three" | "five"


class TarotSelectCardsRequest(BaseModel):
    cards: List[str]  # örn ["the_fool", "the_sun", "death"]


class TarotMarkPaidRequest(BaseModel):
    payment_ref: Optional[str] = None


class TarotRatingRequest(BaseModel):
    rating: int  # 1..5


class TarotReading(BaseModel):
    id: str
    topic: str
    question: str
    name: str
    age: Optional[int] = None

    spread_type: str
    selected_cards: List[str] = []

    status: str
    result_text: Optional[str] = None
    rating: Optional[int] = None

    is_paid: bool = False
    payment_ref: Optional[str] = None
    created_at: Optional[datetime] = None

# app/schemas/coffee.py
from pydantic import BaseModel, Field
from typing import Optional, List, Literal
from datetime import datetime

CoffeeStatus = Literal[
    "pending_payment",
    "photos_uploaded",
    "paid",
    "processing",
    "completed",
]

class CoffeeStartRequest(BaseModel):
    topic: str
    question: str
    name: str
    age: Optional[int] = None

class CoffeeReading(BaseModel):
    id: str
    topic: str
    question: str
    name: str
    age: Optional[int] = None

    photos: List[str] = Field(default_factory=list)
    status: CoffeeStatus = "pending_payment"

    # ✅ ana alan
    comment: Optional[str] = None
    # ✅ alias (DB'deki isim)
    result_text: Optional[str] = None

    rating: Optional[int] = None
    is_paid: bool = False
    payment_ref: Optional[str] = None

    created_at: datetime

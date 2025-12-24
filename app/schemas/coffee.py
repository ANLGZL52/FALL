# app/schemas/coffee.py
from pydantic import BaseModel, Field
from typing import Optional, List, Literal
from datetime import datetime

CoffeeStatus = Literal[
    "pending_payment",
    "photos_uploaded",
    "invalid_photos",
    "paid",
    "processing",
    "completed",
]

class CoffeeStartRequest(BaseModel):
    topic: str
    question: str
    relationship_status: Optional[str] = None
    big_decision: Optional[str] = None
    name: str
    age: Optional[int] = None

class CoffeeReading(BaseModel):
    id: str
    topic: str
    question: str
    relationship_status: Optional[str] = None
    big_decision: Optional[str] = None
    name: str
    age: Optional[int] = None

    photos: List[str] = Field(default_factory=list)
    status: CoffeeStatus = "pending_payment"
    comment: Optional[str] = None
    rating: Optional[int] = None

    is_paid: bool = False
    payment_ref: Optional[str] = None

    invalid_reason: Optional[str] = None
    created_at: datetime

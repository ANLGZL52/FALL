from __future__ import annotations

from typing import Optional
from datetime import datetime
from uuid import uuid4

from sqlmodel import SQLModel, Field


class HandReadingDB(SQLModel, table=True):
    __tablename__ = "hand_readings"

    id: str = Field(default_factory=lambda: str(uuid4()), primary_key=True, index=True)

    topic: str = Field(default="Genel", index=True)
    question: str = Field(default="")

    name: str = Field(default="", index=True)
    age: Optional[int] = Field(default=None)

    images_json: str = Field(default="[]")
    result_text: Optional[str] = Field(default=None)

    status: str = Field(default="created", index=True)
    is_paid: bool = Field(default=False)
    payment_ref: Optional[str] = Field(default=None)

    invalid_reason: Optional[str] = Field(default=None)  # el değilse neden

    rating: Optional[int] = Field(default=None)

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

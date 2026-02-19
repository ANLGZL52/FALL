# app/models/payment_db.py
from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import uuid4

from sqlmodel import SQLModel, Field


class PaymentDB(SQLModel, table=True):
    __tablename__ = "payments"

    id: str = Field(
        default_factory=lambda: f"PAY-{uuid4().hex}",
        primary_key=True,
        index=True,
    )

    device_id: str = Field(index=True)

    reading_id: str = Field(index=True)
    product: str = Field(index=True)
    sku: str = Field(index=True)

    amount: float
    currency: str = Field(default="TRY")

    status: str = Field(index=True, default="pending")  # pending/verified/failed/canceled

    platform: Optional[str] = Field(default=None, index=True)
    transaction_id: Optional[str] = Field(default=None, index=True)

    purchase_token: Optional[str] = Field(default=None, index=True)
    receipt_data: Optional[str] = Field(default=None)

    created_at: datetime = Field(default_factory=datetime.utcnow)
    verified_at: Optional[datetime] = Field(default=None)

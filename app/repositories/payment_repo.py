# app/repositories/payment_repo.py
from __future__ import annotations

from datetime import datetime
from uuid import uuid4
from typing import Optional, Literal

from fastapi import HTTPException
from sqlmodel import Session, select

from app.core.products import get_sku_info
from app.models.payment_db import PaymentDB

PlatformType = Literal["google_play", "app_store"]


class PaymentRepo:
    def create_intent(
        self,
        *,
        session: Session,
        device_id: str,
        reading_id: str,
        sku: str,
    ) -> PaymentDB:
        sku_info = get_sku_info(sku)
        if not sku_info:
            raise HTTPException(status_code=422, detail=f"Unknown sku: {sku}")

        payment_id = f"PAY-{uuid4().hex}"

        payment = PaymentDB(
            id=payment_id,
            device_id=device_id,
            reading_id=reading_id,
            sku=sku,
            product=sku_info.product,
            amount=float(sku_info.amount),
            currency="TRY",
            status="pending",
            created_at=datetime.utcnow(),
        )
        session.add(payment)
        session.commit()
        session.refresh(payment)
        return payment

    def get(self, *, session: Session, payment_id: str) -> Optional[PaymentDB]:
        return session.exec(select(PaymentDB).where(PaymentDB.id == payment_id)).first()

    def reject_if_transaction_used(
        self,
        *,
        session: Session,
        platform: PlatformType,
        transaction_id: str,
        current_payment_id: str,
    ) -> None:
        tx = (transaction_id or "").strip()
        if not tx:
            return

        existing = session.exec(
            select(PaymentDB).where(
                PaymentDB.platform == platform,
                PaymentDB.transaction_id == tx,
                PaymentDB.id != current_payment_id,
                PaymentDB.status == "verified",
            )
        ).first()

        if existing:
            raise HTTPException(status_code=409, detail="transaction_id already used")

    def mark_verified(
        self,
        *,
        session: Session,
        payment: PaymentDB,
        platform: PlatformType,
        transaction_id: str,
        purchase_token: Optional[str],
        receipt_data: Optional[str],
    ) -> PaymentDB:
        self.reject_if_transaction_used(
            session=session,
            platform=platform,
            transaction_id=transaction_id,
            current_payment_id=payment.id,
        )

        payment.status = "verified"
        payment.platform = platform
        payment.transaction_id = (transaction_id or "").strip()
        payment.purchase_token = purchase_token
        payment.receipt_data = receipt_data
        payment.verified_at = datetime.utcnow()

        session.add(payment)
        session.commit()
        session.refresh(payment)
        return payment


payment_repo = PaymentRepo()

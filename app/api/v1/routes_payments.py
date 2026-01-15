from __future__ import annotations

from datetime import datetime
from uuid import uuid4
from typing import Optional, Literal, Dict, Tuple

from fastapi import APIRouter, HTTPException, Depends, Header
from pydantic import BaseModel, Field as PField
from sqlmodel import SQLModel, Field, Session, select

from app.db import get_session
from app.schemas.payments import StartPaymentRequest, StartPaymentResponse

# ✅ IAP verify service (NEW)
from app.services.iap_verify_service import verify_google_play, verify_app_store

# repos
from app.repositories import tarot_repo
from app.repositories.hand_repo import (
    get_reading as hand_get_reading,
    list_photos as hand_list_photos,
    update_reading as hand_update_reading,
)
from app.repositories.coffee_repo import (
    get_reading as coffee_get_reading,
    list_photos as coffee_list_photos,
    update_reading as coffee_update_reading,
)
from app.repositories.numerology_repo import NumerologyRepo
from app.repositories.birthchart_repo import birthchart_repo
from app.repositories.personality_repo import personality_repo
from app.repositories.synastry_repo import synastry_repo

router = APIRouter(prefix="/payments", tags=["payments"])

# ============================================================
# ✅ SKU CATALOG (Store uyumlu tek kaynak)
# ============================================================

SKU_CATALOG: Dict[str, Tuple[str, float]] = {
    "fall_coffee_49": ("coffee", 49.0),
    "fall_hand_39": ("hand", 39.0),
    "fall_numerology_299": ("numerology", 299.0),
    "fall_birthchart_299": ("birthchart", 299.0),
    "fall_personality_399": ("personality", 399.0),
    "fall_synastry_149": ("synastry", 149.0),
    "fall_tarot_3_149": ("tarot", 149.0),
    "fall_tarot_6_199": ("tarot", 199.0),
    "fall_tarot_12_250": ("tarot", 250.0),
}

# ============================================================
# ✅ LEGACY start endpoint’i bozulmasın diye duruyor
# ============================================================

TAROT_ALLOWED_AMOUNTS = {149.0, 199.0, 250.0}
HAND_AMOUNT = 39.0
COFFEE_AMOUNT = 49.0

# ============================================================
# ✅ Payment Table (SQLModel)
# ============================================================

class PaymentDB(SQLModel, table=True):
    __tablename__ = "payments"

    id: str = Field(primary_key=True, index=True)
    device_id: str = Field(index=True)

    reading_id: str = Field(index=True)
    product: str = Field(index=True)
    sku: str = Field(index=True)

    amount: float
    currency: str = Field(default="TRY")

    # pending/verified/failed/canceled
    status: str = Field(index=True, default="pending")

    # google_play/app_store
    platform: Optional[str] = Field(default=None)

    # Store transaction id
    transaction_id: Optional[str] = Field(default=None, index=True)

    purchase_token: Optional[str] = Field(default=None)
    receipt_data: Optional[str] = Field(default=None)

    created_at: datetime = Field(default_factory=datetime.utcnow)
    verified_at: Optional[datetime] = Field(default=None)


_db_inited = False


def _ensure_db(session: Session) -> None:
    """
    Bozmadan: ilk çağrıda payments tablosunu oluşturur.
    (Prod’da ideal: init_db / startup event ile create_all)
    """
    global _db_inited
    if _db_inited:
        return

    bind = session.get_bind()
    SQLModel.metadata.create_all(bind)
    _db_inited = True


def _require_device_id(x_device_id: Optional[str]) -> str:
    if not x_device_id or len(x_device_id.strip()) < 8:
        raise HTTPException(status_code=400, detail="X-Device-Id header is required")
    return x_device_id.strip()


def _sku_info_or_422(sku: str) -> Tuple[str, float]:
    info = SKU_CATALOG.get(sku)
    if not info:
        raise HTTPException(status_code=422, detail=f"Unknown sku: {sku}")
    return info


def _reject_if_transaction_used(session: Session, platform: str, transaction_id: str, current_payment_id: str) -> None:
    """
    ✅ Replay engeli:
    Aynı platform + transaction_id başka bir payment ile verified olduysa reddet.
    """
    tx = transaction_id.strip()
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


# ============================================================
# ✅ New schemas (minimal)
# ============================================================

class PaymentIntentRequest(BaseModel):
    reading_id: str = PField(..., min_length=3)
    sku: str = PField(..., min_length=3)


class PaymentIntentResponse(BaseModel):
    ok: bool = True
    status: Literal["pending"] = "pending"
    payment_id: str
    reading_id: str
    sku: str
    product: str
    amount: float
    currency: str = "TRY"


class PaymentVerifyRequest(BaseModel):
    payment_id: str = PField(..., min_length=6)
    platform: Literal["google_play", "app_store"]
    sku: str = PField(..., min_length=3)
    transaction_id: str = PField(..., min_length=3)

    purchase_token: Optional[str] = None
    receipt_data: Optional[str] = None


class PaymentVerifyResponse(BaseModel):
    ok: bool = True
    verified: bool
    payment_id: str
    status: str


# ============================================================
# ✅ LEGACY endpoint (bozulmasın)
# ============================================================

@router.post("/start", response_model=StartPaymentResponse)
async def start_payment(req: StartPaymentRequest):
    if req.product == "coffee" and req.amount is None:
        raise HTTPException(status_code=422, detail="amount is required for coffee")

    if req.product == "hand":
        amount = HAND_AMOUNT

    elif req.product == "tarot":
        if req.amount is None:
            raise HTTPException(status_code=422, detail="amount is required for tarot")
        amt = round(float(req.amount), 1)
        if amt not in TAROT_ALLOWED_AMOUNTS:
            raise HTTPException(
                status_code=422,
                detail=f"invalid tarot amount: {amt}. allowed: {sorted(TAROT_ALLOWED_AMOUNTS)}",
            )
        amount = amt

    elif req.product == "coffee":
        amount = float(req.amount or COFFEE_AMOUNT)

    else:
        amount = float(req.amount or 0.0)

    payment_id = f"TEST-{uuid4().hex}"

    return StartPaymentResponse(
        ok=True,
        status="success",
        provider="mock",
        product=req.product,
        reading_id=req.reading_id,
        amount=amount,
        payment_id=payment_id,
        payment_ref=payment_id,
    )


# ============================================================
# ✅ NEW Store/IAP endpoints
# ============================================================

@router.post("/intent", response_model=PaymentIntentResponse)
async def create_intent(
    req: PaymentIntentRequest,
    session: Session = Depends(get_session),
    x_device_id: Optional[str] = Header(default=None, alias="X-Device-Id"),
):
    _ensure_db(session)
    device_id = _require_device_id(x_device_id)

    product, amount = _sku_info_or_422(req.sku)
    payment_id = f"PAY-{uuid4().hex}"

    payment = PaymentDB(
        id=payment_id,
        device_id=device_id,
        reading_id=req.reading_id,
        sku=req.sku,
        product=product,
        amount=float(amount),
        currency="TRY",
        status="pending",
        created_at=datetime.utcnow(),
    )
    session.add(payment)
    session.commit()

    return PaymentIntentResponse(
        ok=True,
        status="pending",
        payment_id=payment_id,
        reading_id=req.reading_id,
        sku=req.sku,
        product=product,
        amount=float(amount),
        currency="TRY",
    )


@router.post("/verify", response_model=PaymentVerifyResponse)
async def verify_payment(
    req: PaymentVerifyRequest,
    session: Session = Depends(get_session),
    x_device_id: Optional[str] = Header(default=None, alias="X-Device-Id"),
):
    """
    ✅ Store doğrulama + server-side paid açma:
    - tarot ✅
    - hand ✅
    - coffee ✅
    - numerology ✅
    - birthchart ✅
    - personality ✅
    - synastry ✅
    """
    _ensure_db(session)
    device_id = _require_device_id(x_device_id)

    sku_product, _sku_amount = _sku_info_or_422(req.sku)

    payment = session.exec(select(PaymentDB).where(PaymentDB.id == req.payment_id)).first()
    if not payment:
        raise HTTPException(status_code=404, detail="payment not found")

    if payment.device_id != device_id:
        raise HTTPException(status_code=403, detail="payment device mismatch")

    if payment.sku != req.sku:
        raise HTTPException(status_code=422, detail="sku mismatch for this payment")

    if payment.product != sku_product:
        raise HTTPException(status_code=422, detail="product mismatch for this payment")

    # ✅ Verified idempotent
    if payment.status == "verified":
        if payment.transaction_id and payment.transaction_id != req.transaction_id:
            raise HTTPException(status_code=409, detail="payment already verified with different transaction_id")
        return PaymentVerifyResponse(ok=True, verified=True, payment_id=payment.id, status="verified")

    # ✅ Store doğrulama (dev: stub, prod: gerçek doğrulama bekler)
    if req.platform == "google_play":
        res = verify_google_play(
            purchase_token=(req.purchase_token or ""),
            sku=req.sku,
            transaction_id=req.transaction_id,
        )
    else:
        res = verify_app_store(
            receipt_data=(req.receipt_data or ""),
            sku=req.sku,
            transaction_id=req.transaction_id,
        )

    if not res.ok:
        raise HTTPException(status_code=402, detail=f"IAP verification failed: {res.message}")

    # ✅ transaction replay engeli
    _reject_if_transaction_used(session, req.platform, req.transaction_id, current_payment_id=payment.id)

    # verified işaretle
    payment.status = "verified"
    payment.platform = req.platform
    payment.transaction_id = req.transaction_id
    payment.purchase_token = req.purchase_token
    payment.receipt_data = req.receipt_data
    payment.verified_at = datetime.utcnow()
    session.add(payment)
    session.commit()

    # ✅ Product'a göre reading paid aç
    if sku_product == "tarot":
        r = tarot_repo.get_reading(session, payment.reading_id)
        if not r:
            raise HTTPException(status_code=404, detail="Tarot reading not found for this payment")
        if not r.get_cards():
            raise HTTPException(status_code=400, detail="Cards must be selected before verifying payment")

        r.is_paid = True
        r.payment_ref = payment.id
        r.status = "paid"
        r.updated_at = datetime.utcnow()
        tarot_repo.update_reading(session, r)

    elif sku_product == "hand":
        r = hand_get_reading(session, payment.reading_id)
        if not r:
            raise HTTPException(status_code=404, detail="Hand reading not found for this payment")
        photos = hand_list_photos(r)
        if not photos:
            raise HTTPException(status_code=400, detail="Photos must be uploaded before verifying payment")

        r.is_paid = True
        r.payment_ref = payment.id
        r.status = "paid"
        r.updated_at = datetime.utcnow()
        hand_update_reading(session, r)

    elif sku_product == "coffee":
        r = coffee_get_reading(session, payment.reading_id)
        if not r:
            raise HTTPException(status_code=404, detail="Coffee reading not found for this payment")
        photos = coffee_list_photos(r)
        if not photos:
            raise HTTPException(status_code=400, detail="Photos must be uploaded before verifying payment")

        r.is_paid = True
        r.payment_ref = payment.id
        r.status = "paid"
        r.updated_at = datetime.utcnow()
        coffee_update_reading(session, r)

    elif sku_product == "numerology":
        nrepo = NumerologyRepo()
        obj = nrepo.get(session=session, reading_id=payment.reading_id)
        if not obj:
            raise HTTPException(status_code=404, detail="Numerology reading not found for this payment")
        updated = nrepo.mark_paid(session=session, reading_id=payment.reading_id, payment_ref=payment.id)
        if not updated:
            raise HTTPException(status_code=500, detail="Numerology mark_paid failed")

    elif sku_product == "birthchart":
        reading = birthchart_repo.get(session=session, reading_id=payment.reading_id)
        if not reading:
            raise HTTPException(status_code=404, detail="Birthchart reading not found for this payment")
        updated = birthchart_repo.mark_paid(session=session, reading_id=payment.reading_id, payment_ref=payment.id)
        if not updated:
            raise HTTPException(status_code=500, detail="Birthchart mark_paid failed")

    elif sku_product == "personality":
        reading = personality_repo.get(session=session, reading_id=payment.reading_id)
        if not reading:
            raise HTTPException(status_code=404, detail="Personality reading not found for this payment")
        updated = personality_repo.mark_paid(session=session, reading_id=payment.reading_id, payment_ref=payment.id)
        if not updated:
            raise HTTPException(status_code=500, detail="Personality mark_paid failed")

    elif sku_product == "synastry":
        reading = synastry_repo.get(session=session, reading_id=payment.reading_id)
        if not reading:
            raise HTTPException(status_code=404, detail="Synastry reading not found for this payment")
        updated = synastry_repo.mark_paid(session=session, reading_id=payment.reading_id, payment_ref=payment.id)
        if not updated:
            raise HTTPException(status_code=500, detail="Synastry mark_paid failed")

    else:
        raise HTTPException(status_code=422, detail=f"Unsupported product: {sku_product}")

    return PaymentVerifyResponse(ok=True, verified=True, payment_id=payment.id, status="verified")

from uuid import uuid4
from fastapi import APIRouter, HTTPException

from app.schemas.payments import StartPaymentRequest, StartPaymentResponse

router = APIRouter(prefix="/payments", tags=["payments"])

# ✅ Tarot paket fiyatları (UI ile aynı)
TAROT_ALLOWED_AMOUNTS = {49.9, 79.9, 119.9}


@router.post("/start", response_model=StartPaymentResponse)
async def start_payment(req: StartPaymentRequest):
    """
    Kurallar:
    - coffee -> amount ZORUNLU
    - hand   -> amount backend tarafından set edilir
    - tarot  -> amount ZORUNLU + izinli paketlerden biri olmalı
    """

    # 🔒 coffee için amount zorunlu
    if req.product == "coffee" and req.amount is None:
        raise HTTPException(status_code=422, detail="amount is required for coffee")

    # 🪄 hand için backend fiyat belirler
    if req.product == "hand":
        amount = 75.0

    # 🔮 tarot için amount zorunlu + whitelist
    elif req.product == "tarot":
        if req.amount is None:
            raise HTTPException(status_code=422, detail="amount is required for tarot")

        # float hassasiyetine karşı yuvarla
        amt = round(float(req.amount), 1)
        if amt not in TAROT_ALLOWED_AMOUNTS:
            raise HTTPException(
                status_code=422,
                detail=f"invalid tarot amount: {amt}. allowed: {sorted(TAROT_ALLOWED_AMOUNTS)}",
            )
        amount = amt

    # diğer ürünler (şimdilik)
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

from uuid import uuid4
from fastapi import APIRouter, HTTPException

from app.schemas.payments import (
    StartPaymentRequest,
    StartPaymentResponse,
)

router = APIRouter(prefix="/payments", tags=["payments"])


@router.post("/start", response_model=StartPaymentResponse)
async def start_payment(req: StartPaymentRequest):
    """
    Kurallar:
    - coffee -> amount ZORUNLU
    - hand   -> amount backend tarafından set edilir
    """

    # 🔒 coffee için amount zorunlu
    if req.product == "coffee" and req.amount is None:
        raise HTTPException(status_code=422, detail="amount is required for coffee")

    # 🪄 hand için backend fiyat belirler
    if req.product == "hand":
        amount = 75.0  # el falı fiyatı (istediğin gibi değiştir)
    else:
        amount = req.amount or 0

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

# app/api/v1/routes_payments.py
from fastapi import APIRouter
from pydantic import BaseModel
from uuid import uuid4

router = APIRouter(prefix="/payments", tags=["payments"])

class StartPaymentRequest(BaseModel):
    reading_id: str
    amount: float

class StartPaymentResponse(BaseModel):
    payment_id: str
    status: str  # "success" | "failed"

@router.post("/start", response_model=StartPaymentResponse)
async def start_payment(req: StartPaymentRequest):
    # gerçek sistemde: iyzico/stripe doğrulaması burada
    return StartPaymentResponse(payment_id=f"TEST-{uuid4().hex}", status="success")

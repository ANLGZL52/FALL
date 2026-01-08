from typing import Optional, Literal
from pydantic import BaseModel

# ✅ tarot eklendi
ProductType = Literal["coffee", "hand", "tarot"]


class StartPaymentRequest(BaseModel):
    product: ProductType = "coffee"
    reading_id: str
    amount: Optional[float] = None


class StartPaymentResponse(BaseModel):
    ok: bool
    status: str
    provider: str

    product: ProductType
    reading_id: str
    amount: float

    payment_id: str
    payment_ref: str

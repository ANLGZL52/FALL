# app/api/v1/__init__.py
from fastapi import APIRouter

from app.api.v1.routes_coffee import router as coffee_router
from app.api.v1.routes_payments import router as payments_router

# el falı route'un varsa:
try:
    from app.api.v1.routes_hand import router as hand_router
except Exception:
    hand_router = None

api_router = APIRouter()
api_router.include_router(coffee_router, tags=["coffee"])
api_router.include_router(payments_router, tags=["payments"])

if hand_router is not None:
    api_router.include_router(hand_router, tags=["hand"])

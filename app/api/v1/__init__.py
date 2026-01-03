# app/api/v1/__init__.py
from fastapi import APIRouter

from .routes_coffee import router as coffee_router
from .routes_hand import router as hand_router
from .routes_tarot import router as tarot_router
from .routes_numerology import router as numerology_router
from .routes_birthchart import router as birthchart_router
from .routes_personality import router as personality_router
from .routes_payments import router as payments_router
from .routes_synastry import router as synastry_router  # ✅ EKLE

api_router = APIRouter()

api_router.include_router(coffee_router)
api_router.include_router(hand_router)
api_router.include_router(tarot_router)
api_router.include_router(numerology_router)
api_router.include_router(birthchart_router)
api_router.include_router(personality_router)
api_router.include_router(payments_router)
api_router.include_router(synastry_router)  # ✅ EKLE

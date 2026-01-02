from app.api.v1.routes_coffee import router as coffee_router
from app.api.v1.routes_hand import router as hand_router
from app.api.v1.routes_payments import router as payments_router
from app.api.v1.routes_tarot import router as tarot_router
from app.api.v1.routes_numerology import router as numerology_router

__all__ = [
    "coffee_router",
    "hand_router",
    "payments_router",
    "tarot_router",
    "numerology_router",
]

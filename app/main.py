from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.db import init_db
from app.api.v1.routes_coffee import router as coffee_router
from app.api.v1.routes_hand import router as hand_router
from app.api.v1.routes_payments import router as payments_router
from app.api.v1.routes_tarot import router as tarot_router
from app.api.v1.routes_numerology import router as numerology_router
from app.api.v1.routes_birthchart import router as birthchart_router

print("[BOOT] main.py loaded from:", __file__)

app = FastAPI(title="FALL API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup() -> None:
    init_db()


# ✅ hepsi aynı mantıkta /api/v1 altında
app.include_router(coffee_router, prefix="/api/v1")
app.include_router(hand_router, prefix="/api/v1")
app.include_router(payments_router, prefix="/api/v1")
app.include_router(tarot_router, prefix="/api/v1")
app.include_router(numerology_router, prefix="/api/v1")
app.include_router(birthchart_router, prefix="/api/v1")

print("[BOOT] routers included: coffee, hand, payments, tarot, numerology, birthchart")

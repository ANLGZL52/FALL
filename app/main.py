from __future__ import annotations

import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.db import init_db
from app.api.v1.routes_coffee import router as coffee_router
from app.api.v1.routes_hand import router as hand_router
from app.api.v1.routes_payments import router as payments_router

app = FastAPI(title="FALL API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Windows + reload'ta init_db bazen 2 kez tetiklenebiliyor
# Bu flag, aynı process içinde tekrar init olmasını engeller.
_db_initialized = False

@app.on_event("startup")
def on_startup() -> None:
    global _db_initialized
    if _db_initialized:
        return

    # ✅ Uvicorn reload parent/child süreçlerinde karışıklık olmaması için
    # Sadece gerçek server process DB init yapsın.
    # (Uvicorn reload açıkken bir "reloader" process + bir "server" process oluşur.)
    if os.environ.get("RUN_MAIN") == "true" or os.environ.get("UVICORN_RELOAD") == "true":
        init_db()
        _db_initialized = True
    else:
        # reload kapalıysa normal init
        init_db()
        _db_initialized = True


app.include_router(coffee_router, prefix="/api/v1")
app.include_router(hand_router, prefix="/api/v1")
app.include_router(payments_router, prefix="/api/v1")

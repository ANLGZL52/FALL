# app/main.py
from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import api_router  # ✅ bütün router'lar burada
from app.db import init_db  # ✅ DB init + sqlite migration


app = FastAPI(title="FALL API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # dev için
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def _startup() -> None:
    # ✅ create_all + sqlite migration helper'lar burada çalışır
    init_db()


# (opsiyonel ama çok işe yarıyor)
@app.get("/health")
def health():
    return {"ok": True}


# ✅ BÜTÜN ROUTE'LARI TEK SEFERDE EKLER
app.include_router(api_router, prefix="/api/v1")

# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import api_router  # ✅ bunu kullanacağız

app = FastAPI(title="FALL API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # dev için
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ BÜTÜN ROUTE'LARI TEK SEFERDE EKLER
app.include_router(api_router, prefix="/api/v1")

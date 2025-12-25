# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.db import create_db_and_tables
from app.api.v1.routes_coffee import router as coffee_router
from app.api.v1.routes_payments import router as payments_router

app = FastAPI(title="FALL Backend")

@app.on_event("startup")
def on_startup():
    create_db_and_tables()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok"}

# ✅ kritik: /api/v1 prefix ile include
app.include_router(coffee_router, prefix="/api/v1")
app.include_router(payments_router, prefix="/api/v1")

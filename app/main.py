# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import routes_coffee, routes_payments

app = FastAPI(title="FALL Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health():
    return {"status": "ok"}

app.include_router(routes_coffee.router, prefix="/api/v1")
app.include_router(routes_payments.router, prefix="/api/v1")

# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import routes_coffee, routes_payments
from app.db import create_db_and_tables

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
async def health():
    return {"status": "ok"}

app.include_router(routes_coffee.router, prefix="/api/v1")
app.include_router(routes_payments.router, prefix="/api/v1")

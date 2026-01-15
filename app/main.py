from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import api_router
from app.core.config import settings
from app.db import init_db

app = FastAPI(title="Lunaura API")

origins = settings.cors_origins

# "*" varsa allow_credentials=False olmalı
allow_credentials = False if origins == ["*"] else True

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=allow_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def _startup() -> None:
    settings.ensure_dirs()
    init_db()


@app.get("/health")
def health():
    return {"ok": True, "env": settings.environment}


app.include_router(api_router, prefix="/api/v1")

# app/api/v1/routes_coffee.py
from __future__ import annotations

import os
from typing import List, Optional
from datetime import datetime

from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from pydantic import BaseModel
from sqlmodel import Session

from app.db import get_session
from app.core.config import settings
from app.models.coffee_db import CoffeeReadingDB
from app.repositories.coffee_repo import (
    get_reading,
    create_reading,
    update_reading,
    set_photos,
    list_photos,
    set_status,
)
from app.services.storage import save_uploads
from app.services.openai_service import generate_fortune, validate_coffee_images
from app.schemas.coffee import CoffeeStartRequest, CoffeeReading

router = APIRouter(prefix="/coffee", tags=["coffee"])


class MarkPaidRequest(BaseModel):
    payment_ref: Optional[str] = None


class RatingRequest(BaseModel):
    rating: int


def _get_or_404(session: Session, reading_id: str) -> CoffeeReadingDB:
    r = get_reading(session, reading_id)
    if not r:
        raise HTTPException(status_code=404, detail="Reading not found")
    return r


def _to_schema(r: CoffeeReadingDB) -> CoffeeReading:
    photos = list_photos(r)
    result = getattr(r, "result_text", None)

    return CoffeeReading(
        id=r.id,
        topic=r.topic,
        question=r.question,
        name=r.name,
        age=r.age,
        photos=photos,
        status=r.status,
        comment=result,
        result_text=result,
        rating=r.rating,
        is_paid=r.is_paid,
        payment_ref=r.payment_ref,
        created_at=r.created_at,
    )


def _delete_paths(paths: List[str]) -> None:
    for p in paths:
        try:
            if os.path.exists(p):
                os.remove(p)
        except Exception:
            pass


@router.post("/start", response_model=CoffeeReading)
async def start(req: CoffeeStartRequest, session: Session = Depends(get_session)):
    db_obj = CoffeeReadingDB(
        topic=req.topic,
        question=req.question,
        name=req.name,
        age=req.age,
        status="pending_payment",
        is_paid=False,
        payment_ref=None,
        result_text=None,
        images_json="[]",
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    db_obj = create_reading(session, db_obj)
    return _to_schema(db_obj)


@router.post("/{reading_id}/upload", response_model=CoffeeReading)
@router.post("/{reading_id}/upload-images", response_model=CoffeeReading)
async def upload_images(
    reading_id: str,
    files: List[UploadFile] = File(...),
    session: Session = Depends(get_session),
):
    _get_or_404(session, reading_id)

    # ✅ 3-5 foto kuralı (config’ten)
    if len(files) < settings.min_photos or len(files) > settings.max_photos:
        raise HTTPException(
            status_code=400,
            detail=f"Foto sayısı {settings.min_photos}-{settings.max_photos} aralığında olmalı.",
        )

    saved = await save_uploads(reading_id, files)

    # ✅ Upload sonrası DOĞRULAMA: kahve fincanı içi mi?
    verdict = validate_coffee_images(saved)
    if not verdict.get("ok", False):
        _delete_paths(saved)  # mağduriyeti önle
        reason = verdict.get("reason", "Görseller kahve fincanı içi değil.")
        raise HTTPException(status_code=400, detail=reason)

    r = set_photos(session, reading_id, saved)
    return _to_schema(r)


@router.post("/{reading_id}/mark-paid", response_model=CoffeeReading)
async def mark_paid(reading_id: str, body: MarkPaidRequest, session: Session = Depends(get_session)):
    r = _get_or_404(session, reading_id)

    # ✅ ekstra güvenlik: foto yoksa ödeme yok
    if not list_photos(r):
        raise HTTPException(status_code=400, detail="Ödeme için önce fotoğraf yüklemelisin.")

    r.is_paid = True
    r.payment_ref = body.payment_ref
    r.status = "paid"
    r = update_reading(session, r)
    return _to_schema(r)


@router.post("/{reading_id}/generate", response_model=CoffeeReading)
async def generate(reading_id: str, session: Session = Depends(get_session)):
    r = _get_or_404(session, reading_id)

    photos = list_photos(r)
    if not photos:
        raise HTTPException(status_code=400, detail="No photos uploaded")

    if not r.is_paid:
        raise HTTPException(status_code=400, detail="Payment required before reading")

    # idempotent
    if r.status == "completed" and getattr(r, "result_text", None):
        return _to_schema(r)

    # ✅ generate öncesi ekstra doğrulama (opsiyonel ama sağlam)
    verdict = validate_coffee_images(photos)
    if not verdict.get("ok", False):
        raise HTTPException(status_code=400, detail=verdict.get("reason", "Görseller kahve fincanı içi değil."))

    r = set_status(session, reading_id, "processing")

    comment = generate_fortune(
        name=r.name,
        topic=r.topic,
        question=r.question,
        image_paths=photos,
    )

    # Eğer model yine de "fincan değil" diyorsa completed yapmayalım
    if comment.strip() == "Görseller kahve fincanı içi görünmüyor.":
        r = set_status(session, reading_id, "paid", comment=None)  # geri al
        raise HTTPException(status_code=400, detail="Görseller kahve fincanı içi görünmüyor.")

    r = set_status(session, reading_id, "completed", comment=comment)
    return _to_schema(r)


@router.get("/{reading_id}", response_model=CoffeeReading)
async def detail(reading_id: str, session: Session = Depends(get_session)):
    r = _get_or_404(session, reading_id)
    return _to_schema(r)


@router.post("/{reading_id}/rate", response_model=CoffeeReading)
async def rate(reading_id: str, req: RatingRequest, session: Session = Depends(get_session)):
    r = _get_or_404(session, reading_id)
    if req.rating < 1 or req.rating > 5:
        raise HTTPException(status_code=400, detail="Rating must be 1..5")
    r.rating = req.rating
    r = update_reading(session, r)
    return _to_schema(r)

from __future__ import annotations

import os
from typing import List, Optional
from datetime import datetime
from uuid import uuid4

from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from pydantic import BaseModel
from sqlmodel import Session

from app.db import get_session
from app.core.device import get_device_id
from app.models.hand_db import HandReadingDB
from app.repositories.hand_repo import (
    get_reading,
    create_reading,
    update_reading,
    set_photos,
    list_photos,
    set_status,
)
from app.services.storage import save_uploads
from app.services.openai_service import generate_hand_fortune, validate_hand_images
from app.schemas.hand import HandStartRequest, HandReading

router = APIRouter(prefix="/hand", tags=["hand"])


class MarkPaidRequest(BaseModel):
    payment_ref: Optional[str] = None


class RatingRequest(BaseModel):
    rating: int


def _get_or_404_owner(session: Session, reading_id: str, device_id: str) -> HandReadingDB:
    """
    ✅ Ownership check: sadece aynı cihaz bu reading'e erişebilir.
    Legacy kayıtlar için device_id boşsa ilk erişimde bağlanır.
    """
    r = get_reading(session, reading_id)
    if not r:
        raise HTTPException(status_code=404, detail="El falı bulunamadı.")

    rid = (getattr(r, "device_id", None) or "").strip()

    # ✅ Eğer kayıt device_id ile kilitliyse ve farklı cihazsa => 404
    if rid and rid != device_id:
        raise HTTPException(status_code=404, detail="El falı bulunamadı.")

    # ✅ Legacy: device_id boşsa ilk erişimde bağla
    if not rid:
        try:
            setattr(r, "device_id", device_id)
            r.updated_at = datetime.utcnow()
            update_reading(session, r)
        except Exception:
            # Kolon yoksa / migration eksikse patlatma
            pass

    return r


def _to_schema(r: HandReadingDB) -> HandReading:
    photos = list_photos(r)
    result = getattr(r, "result_text", None)

    return HandReading(
        id=r.id,
        topic=r.topic,
        question=r.question,
        name=r.name,
        age=r.age,
        dominant_hand=getattr(r, "dominant_hand", None),
        photo_hand=getattr(r, "photo_hand", None),
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


def _hand_upload_user_message(verdict: dict) -> str:
    reason = (verdict.get("reason") or "").strip()
    base = (
        "Bu görseller el falı için uygun görünmüyor. "
        "Lütfen sadece AVUÇ İÇİ (palm) fotoğrafı yükleyin.\n\n"
        "İpucu: Avuç içi tamamen kadrajda olsun, ışık iyi olsun, çizgiler net görünsün."
    )
    if reason and len(reason) <= 120:
        return f"{base}\n\nNeden: {reason}"
    return base


# ------------------------------------------------
# START
# ------------------------------------------------
@router.post("/start", response_model=HandReading)
async def start(
    req: HandStartRequest,
    session: Session = Depends(get_session),
    device_id: str = Depends(get_device_id),
):
    db_obj = HandReadingDB(
        id=str(uuid4()),
        topic=req.topic,
        question=req.question,
        name=req.name,
        age=req.age,
        dominant_hand=req.dominant_hand,
        photo_hand=req.photo_hand,
        relationship_status=req.relationship_status,
        big_decision=req.big_decision,
        status="pending_payment",
        is_paid=False,
        payment_ref=None,
        result_text=None,
        images_json="[]",
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )

    # ✅ device_id yaz (kolon varsa)
    try:
        setattr(db_obj, "device_id", device_id)
    except Exception:
        pass

    db_obj = create_reading(session, db_obj)
    return _to_schema(db_obj)


# ------------------------------------------------
# UPLOAD IMAGES
# ------------------------------------------------
@router.post("/{reading_id}/upload-images", response_model=HandReading)
async def upload_images(
    reading_id: str,
    files: List[UploadFile] = File(...),
    session: Session = Depends(get_session),
    device_id: str = Depends(get_device_id),
):
    _get_or_404_owner(session, reading_id, device_id)

    # ✅ 1–3 foto kuralı
    if len(files) < 1 or len(files) > 3:
        raise HTTPException(
            status_code=400,
            detail="Lütfen 1 ile 3 arasında el fotoğrafı yükleyin.",
        )

    saved = await save_uploads(reading_id, files)

    verdict = validate_hand_images(saved)
    if not verdict.get("ok", False):
        _delete_paths(saved)
        raise HTTPException(
            status_code=400,
            detail=_hand_upload_user_message(verdict),
        )

    r2 = set_photos(session, reading_id, saved)
    return _to_schema(r2)


# ------------------------------------------------
# MARK PAID (legacy / mock)
# ------------------------------------------------
@router.post("/{reading_id}/mark-paid", response_model=HandReading)
async def mark_paid(
    reading_id: str,
    body: MarkPaidRequest,
    session: Session = Depends(get_session),
    device_id: str = Depends(get_device_id),
):
    r = _get_or_404_owner(session, reading_id, device_id)

    if not list_photos(r):
        raise HTTPException(
            status_code=400,
            detail="Ödeme yapmadan önce el fotoğrafı yüklemelisiniz.",
        )

    if not body.payment_ref:
        raise HTTPException(status_code=422, detail="payment_ref gerekli.")

    if not body.payment_ref.startswith("TEST-"):
        raise HTTPException(
            status_code=403,
            detail="Gerçek ödemeler için /payments/verify kullanılır.",
        )

    # ✅ idempotent
    if r.is_paid and r.payment_ref:
        return _to_schema(r)

    r.is_paid = True
    r.payment_ref = body.payment_ref
    r.status = "paid"
    r.updated_at = datetime.utcnow()

    r = update_reading(session, r)
    return _to_schema(r)


# ------------------------------------------------
# GENERATE
# ------------------------------------------------
@router.post("/{reading_id}/generate", response_model=HandReading)
async def generate(
    reading_id: str,
    session: Session = Depends(get_session),
    device_id: str = Depends(get_device_id),
):
    r = _get_or_404_owner(session, reading_id, device_id)

    photos = list_photos(r)
    if not photos:
        raise HTTPException(status_code=400, detail="El fotoğrafı yüklenmedi.")

    if not r.is_paid:
        raise HTTPException(status_code=402, detail="Ödeme yapılmadan yorum oluşturulamaz.")

    # idempotent
    if (r.status or "").lower().strip() == "completed" and (r.result_text or "").strip():
        return _to_schema(r)

    # processing ise tekrar çağırma (kalkan)
    if (r.status or "").lower().strip() == "processing":
        return _to_schema(r)

    verdict = validate_hand_images(photos)
    if not verdict.get("ok", False):
        raise HTTPException(
            status_code=400,
            detail=_hand_upload_user_message(verdict),
        )

    set_status(session, reading_id, "processing")

    try:
        comment = generate_hand_fortune(
            name=r.name,
            topic=r.topic,
            question=r.question,
            dominant_hand=getattr(r, "dominant_hand", None),
            photo_hand=getattr(r, "photo_hand", None),
            image_paths=photos,
        )

        if not comment or not comment.strip():
            set_status(session, reading_id, "paid")
            raise HTTPException(status_code=500, detail="El falı yorumu üretilemedi.")

        r2 = set_status(session, reading_id, "completed", comment=comment)
        return _to_schema(r2)

    except HTTPException:
        raise
    except Exception as e:
        # tekrar denemeye izin ver
        try:
            set_status(session, reading_id, "paid")
        except Exception:
            pass
        raise HTTPException(status_code=500, detail=f"El falı yorum üretilemedi: {e}")


# ------------------------------------------------
# DETAIL
# ------------------------------------------------
@router.get("/{reading_id}", response_model=HandReading)
async def detail(
    reading_id: str,
    session: Session = Depends(get_session),
    device_id: str = Depends(get_device_id),
):
    r = _get_or_404_owner(session, reading_id, device_id)
    return _to_schema(r)


# ------------------------------------------------
# RATE
# ------------------------------------------------
@router.post("/{reading_id}/rate", response_model=HandReading)
async def rate(
    reading_id: str,
    req: RatingRequest,
    session: Session = Depends(get_session),
    device_id: str = Depends(get_device_id),
):
    r = _get_or_404_owner(session, reading_id, device_id)

    if req.rating < 1 or req.rating > 5:
        raise HTTPException(status_code=400, detail="Puan 1 ile 5 arasında olmalı.")

    r.rating = req.rating
    r.updated_at = datetime.utcnow()
    r = update_reading(session, r)

    return _to_schema(r)

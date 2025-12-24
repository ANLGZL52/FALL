# app/api/v1/routes_coffee.py
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from pydantic import BaseModel
from typing import List
from uuid import uuid4
from datetime import datetime

from sqlmodel import Session

from app.schemas.coffee import CoffeeStartRequest, CoffeeReading
from app.core.config import settings
from app.services.storage import save_uploads, delete_reading_uploads
from app.services.openai_service import validate_coffee_images, generate_fortune

from app.db import get_session
from app.models.coffee_db import CoffeeReadingDB
from app.repositories.coffee_repo import (
    get_reading,
    create_reading,
    update_reading,
    set_photos,
    list_photos,
    set_status,
)

router = APIRouter(prefix="/coffee", tags=["coffee"])


def _to_schema(r: CoffeeReadingDB) -> CoffeeReading:
    photos = list_photos(r)
    return CoffeeReading(
        id=r.id,
        topic=r.topic,
        question=r.question,
        relationship_status=r.relationship_status,
        big_decision=r.big_decision,
        name=r.name,
        age=r.age,
        photos=photos,
        status=r.status,
        comment=r.comment,
        rating=r.rating,
        is_paid=r.is_paid,
        payment_ref=r.payment_ref,
        invalid_reason=r.invalid_reason,
        created_at=r.created_at,
    )


def _get_or_404(session: Session, reading_id: str) -> CoffeeReadingDB:
    r = get_reading(session, reading_id)
    if not r:
        raise HTTPException(status_code=404, detail="Reading not found")
    return r


class RatingRequest(BaseModel):
    rating: int


class MarkPaidRequest(BaseModel):
    payment_ref: str | None = None


@router.post("/start", response_model=CoffeeReading)
async def start(req: CoffeeStartRequest, session: Session = Depends(get_session)):
    reading_id = str(uuid4())
    db_obj = CoffeeReadingDB(
        id=reading_id,
        topic=req.topic,
        question=req.question,
        relationship_status=req.relationship_status,
        big_decision=req.big_decision,
        name=req.name,
        age=req.age,
        photos_json="[]",
        status="pending_payment",
        comment=None,
        rating=None,
        is_paid=False,
        payment_ref=None,
        invalid_reason=None,
        created_at=datetime.utcnow(),
    )
    db_obj = create_reading(session, db_obj)
    return _to_schema(db_obj)


@router.post("/{reading_id}/upload-images", response_model=CoffeeReading)
async def upload_images(
    reading_id: str,
    files: List[UploadFile] = File(...),
    session: Session = Depends(get_session),
):
    _get_or_404(session, reading_id)

    if len(files) < settings.MIN_PHOTOS or len(files) > settings.MAX_PHOTOS:
        raise HTTPException(
            status_code=400,
            detail=f"Lütfen {settings.MIN_PHOTOS}-{settings.MAX_PHOTOS} arası foto yükle.",
        )

    saved = await save_uploads(reading_id, files)
    r = set_photos(session, reading_id, saved)
    return _to_schema(r)


@router.post("/{reading_id}/validate-images", response_model=CoffeeReading)
async def validate_images(reading_id: str, session: Session = Depends(get_session)):
    r = _get_or_404(session, reading_id)
    photos = list_photos(r)

    if not photos:
        raise HTTPException(status_code=400, detail="No photos uploaded")

    # ✅ BUG FIX: r.photos değil, photos gönder
    try:
        res = validate_coffee_images(photos)
    except FileNotFoundError as e:
        r = set_status(session, reading_id, "invalid_photos", invalid_reason=str(e))
        raise HTTPException(status_code=400, detail=f"Fotoğraflar bulunamadı: {str(e)}")

    if not res["ok"]:
        r = set_status(session, reading_id, "invalid_photos", invalid_reason=res["reason"])
        raise HTTPException(status_code=400, detail=f"Fotoğraflar uygun değil: {r.invalid_reason}")

    r.invalid_reason = None
    r = update_reading(session, r)
    return _to_schema(r)


@router.post("/{reading_id}/mark-paid", response_model=CoffeeReading)
async def mark_paid(reading_id: str, body: MarkPaidRequest, session: Session = Depends(get_session)):
    r = _get_or_404(session, reading_id)
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
    if r.status == "invalid_photos":
        raise HTTPException(status_code=400, detail=f"Invalid photos: {r.invalid_reason}")
    if not r.is_paid:
        raise HTTPException(status_code=400, detail="Payment required before reading")

    # ✅ 1) completed ise cache dön (idempotent)
    if r.status == "completed" and r.comment:
        return _to_schema(r)

    # ✅ 2) processing ise ikinci çağrıyı engelle
    if r.status == "processing":
        raise HTTPException(status_code=409, detail="Reading is already processing. Please wait.")

    # ✅ 3) processing durumuna çek ve commit et (kilit etkisi)
    r = set_status(session, reading_id, "processing", invalid_reason=None)

    # ✅ 4) tekrar doğrula + üret
    try:
        res = validate_coffee_images(photos)
        if not res["ok"]:
            r = set_status(session, reading_id, "invalid_photos", invalid_reason=res["reason"])
            raise HTTPException(status_code=400, detail=f"Fotoğraflar uygun değil: {r.invalid_reason}")

        comment = generate_fortune(
            name=r.name,
            topic=r.topic,
            question=r.question,
            image_paths=photos,
            relationship_status=r.relationship_status,
            big_decision=r.big_decision,
        )

        r = set_status(session, reading_id, "completed", comment=comment, invalid_reason=None)

        # ✅ Opsiyonel: disk şişmesin diye completed sonrası foto klasörünü sil
        # delete_reading_uploads(reading_id)

        return _to_schema(r)

    except FileNotFoundError as e:
        # Foto yolu bozulduysa: invalid_photos
        r = set_status(session, reading_id, "invalid_photos", invalid_reason=str(e))
        raise HTTPException(status_code=400, detail=f"Fotoğraflar bulunamadı: {str(e)}")

    except HTTPException:
        # HTTPException'ı olduğu gibi yükselt
        raise

    except Exception as e:
        # Fail-safe: processing'te kalmasın
        r = set_status(session, reading_id, "paid", invalid_reason=f"Generate error: {str(e)}")
        raise HTTPException(status_code=500, detail="Fal üretimi sırasında beklenmeyen bir hata oluştu.")


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

# app/api/v1/routes_coffee.py
from __future__ import annotations

from typing import List, Optional
from datetime import datetime

from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from pydantic import BaseModel
from sqlmodel import Session

from app.db import get_session
from app.core.config import settings
from app.core.device import get_device_id
from app.models.coffee_db import CoffeeReadingDB
from app.repositories.coffee_repo import (
    get_reading,
    create_reading,
    update_reading,
    set_photos,
    list_photos,
    set_status,
)
from app.services.storage import save_uploads, resolve_stable_path
from app.services.openai_service import generate_fortune, validate_coffee_images
from app.schemas.coffee import CoffeeStartRequest, CoffeeReading

router = APIRouter(prefix="/coffee", tags=["coffee"])


class MarkPaidRequest(BaseModel):
    payment_ref: Optional[str] = None


class RatingRequest(BaseModel):
    rating: int


def _get_or_404_owner(session: Session, reading_id: str, device_id: str) -> CoffeeReadingDB:
    """
    Ownership check: sadece aynı cihaz bu reading'e erişebilir.
    Legacy kayıtlar için device_id boşsa, ilk erişimde bağlanır.
    """
    r = get_reading(session, reading_id)
    if not r:
        raise HTTPException(status_code=404, detail="Reading not found")

    rid = (getattr(r, "device_id", None) or "").strip()

    if rid and rid != device_id:
        raise HTTPException(status_code=404, detail="Reading not found")

    if not rid:
        try:
            setattr(r, "device_id", device_id)
            r.updated_at = datetime.utcnow()
            update_reading(session, r)
        except Exception:
            pass

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


def _disk_paths(stable_paths: List[str]) -> List[str]:
    return [str(resolve_stable_path(p)) for p in (stable_paths or [])]


def _delete_uploaded(stable_paths: List[str]) -> None:
    for sp in stable_paths or []:
        try:
            p = resolve_stable_path(sp)
            if p.exists():
                p.unlink()
        except Exception:
            pass


@router.post("/start", response_model=CoffeeReading)
async def start(
    req: CoffeeStartRequest,
    session: Session = Depends(get_session),
    device_id: str = Depends(get_device_id),
):
    """
    Akış:
      1) /coffee/start -> reading_id (pending_payment)
      2) /coffee/{id}/upload-images -> foto yükle (images_uploaded)
      3) Store ödeme -> /payments/intent + /payments/verify (paid)
      4) /coffee/{id}/generate -> yorum üret (processing -> done)
    """
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
        device_id=device_id,
    )
    db_obj = create_reading(session, db_obj)
    return _to_schema(db_obj)


@router.post("/{reading_id}/upload", response_model=CoffeeReading)
@router.post("/{reading_id}/upload-images", response_model=CoffeeReading)
async def upload_images(
    reading_id: str,
    files: List[UploadFile] = File(...),
    session: Session = Depends(get_session),
    device_id: str = Depends(get_device_id),
):
    _get_or_404_owner(session, reading_id, device_id)

    # 3-5 foto kuralı
    if len(files) < settings.min_photos or len(files) > settings.max_photos:
        raise HTTPException(
            status_code=400,
            detail=f"Foto sayısı {settings.min_photos}-{settings.max_photos} aralığında olmalı.",
        )

    # 1) Kaydet (DB'ye yazılacak stable path listesi gelir)
    saved_stable = await save_uploads(reading_id, files)

    # 2) Validate (kahve dışı görsel varsa burada patlat)
    try:
        verdict = validate_coffee_images(_disk_paths(saved_stable))
    except Exception as e:
        _delete_uploaded(saved_stable)
        raise HTTPException(status_code=500, detail=f"Görsel doğrulama hatası: {e}")

    if not verdict.get("ok", False):
        _delete_uploaded(saved_stable)
        # ✅ İSTEDİĞİN net mesaj:
        raise HTTPException(
            status_code=400,
            detail="Lütfen yalnızca kahve fincanının iç kısmının fotoğrafını yükleyiniz.",
        )

    # 3) DB’ye stable path yaz + status images_uploaded
    try:
        r2 = set_photos(session, reading_id, saved_stable)
        return _to_schema(r2)
    except Exception as e:
        _delete_uploaded(saved_stable)
        raise HTTPException(status_code=500, detail=f"Foto kaydı başarısız: {e}")


@router.post("/{reading_id}/mark-paid", response_model=CoffeeReading)
async def mark_paid(
    reading_id: str,
    body: MarkPaidRequest,
    session: Session = Depends(get_session),
    device_id: str = Depends(get_device_id),
):
    """
    Legacy/mock akış (TEST-...).
    Real ödeme: /payments/verify.
    """
    r = _get_or_404_owner(session, reading_id, device_id)

    if not list_photos(r):
        raise HTTPException(status_code=400, detail="Ödeme için önce fotoğraf yüklemelisin.")

    if not body.payment_ref:
        raise HTTPException(status_code=422, detail="payment_ref is required")

    if not str(body.payment_ref).startswith("TEST-"):
        raise HTTPException(
            status_code=403,
            detail="mark-paid is legacy only. Use /payments/verify for real payments.",
        )

    if r.is_paid and r.payment_ref:
        return _to_schema(r)

    r.is_paid = True
    r.payment_ref = body.payment_ref
    r.status = "paid"
    r.updated_at = datetime.utcnow()
    r = update_reading(session, r)
    return _to_schema(r)


@router.post("/{reading_id}/generate", response_model=CoffeeReading)
async def generate(
    reading_id: str,
    session: Session = Depends(get_session),
    device_id: str = Depends(get_device_id),
):
    r = _get_or_404_owner(session, reading_id, device_id)

    photos_stable = list_photos(r)
    if not photos_stable:
        raise HTTPException(status_code=400, detail="No photos uploaded")

    if not r.is_paid:
        raise HTTPException(status_code=402, detail="Payment Required")

    status = (r.status or "").lower().strip()
    result_text = (r.result_text or "").strip()

    if result_text:
        return _to_schema(r)

    if status == "processing":
        return _to_schema(r)

    photos_disk = _disk_paths(photos_stable)

    verdict = validate_coffee_images(photos_disk)
    if not verdict.get("ok", False):
        raise HTTPException(
            status_code=400,
            detail="Lütfen yalnızca kahve fincanının iç kısmının fotoğrafını yükleyiniz.",
        )

    set_status(session, reading_id, "processing")

    try:
        comment = generate_fortune(
            name=r.name,
            topic=r.topic,
            question=r.question,
            image_paths=photos_disk,
        )
        comment = (comment or "").strip()

        # Model bazen bu cümleyi döndürür -> yine 400
        if comment == "Görseller kahve fincanı içi görünmüyor.":
            set_status(session, reading_id, "paid", comment=None)
            raise HTTPException(
                status_code=400,
                detail="Lütfen yalnızca kahve fincanının iç kısmının fotoğrafını yükleyiniz.",
            )

        if not comment:
            set_status(session, reading_id, "paid", comment=None)
            raise HTTPException(status_code=500, detail="Yorum üretilemedi (boş sonuç).")

        r2 = set_status(session, reading_id, "done", comment=comment)
        return _to_schema(r2)

    except HTTPException:
        raise
    except Exception as e:
        try:
            set_status(session, reading_id, "paid", comment=None)
        except Exception:
            pass
        raise HTTPException(status_code=500, detail=f"Kahve falı yorum üretilemedi: {e}")


@router.get("/{reading_id}", response_model=CoffeeReading)
async def detail(
    reading_id: str,
    session: Session = Depends(get_session),
    device_id: str = Depends(get_device_id),
):
    r = _get_or_404_owner(session, reading_id, device_id)
    return _to_schema(r)


@router.post("/{reading_id}/rate", response_model=CoffeeReading)
async def rate(
    reading_id: str,
    req: RatingRequest,
    session: Session = Depends(get_session),
    device_id: str = Depends(get_device_id),
):
    r = _get_or_404_owner(session, reading_id, device_id)
    if req.rating < 1 or req.rating > 5:
        raise HTTPException(status_code=400, detail="Rating must be 1..5")
    r.rating = req.rating
    r.updated_at = datetime.utcnow()
    r = update_reading(session, r)
    return _to_schema(r)

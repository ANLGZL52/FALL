# app/api/v1/routes_coffee.py
from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List, Dict
from uuid import uuid4
from datetime import datetime

from app.schemas.coffee import CoffeeStartRequest, CoffeeReading
from app.core.config import settings
from app.services.storage import save_uploads
from app.services.openai_service import validate_coffee_images, generate_fortune

router = APIRouter(prefix="/coffee", tags=["coffee"])

FAKE_DB: Dict[str, CoffeeReading] = {}

def _get(reading_id: str) -> CoffeeReading:
    r = FAKE_DB.get(reading_id)
    if not r:
        raise HTTPException(status_code=404, detail="Reading not found")
    return r

class RatingRequest(BaseModel):
    rating: int

class MarkPaidRequest(BaseModel):
    payment_ref: str | None = None

@router.post("/start", response_model=CoffeeReading)
async def start(req: CoffeeStartRequest):
    reading_id = str(uuid4())
    r = CoffeeReading(
        id=reading_id,
        topic=req.topic,
        question=req.question,
        relationship_status=req.relationship_status,
        big_decision=req.big_decision,
        name=req.name,
        age=req.age,
        photos=[],
        status="pending_payment",
        comment=None,
        rating=None,
        is_paid=False,
        payment_ref=None,
        invalid_reason=None,
        created_at=datetime.utcnow(),
    )
    FAKE_DB[reading_id] = r
    return r

@router.post("/{reading_id}/upload-images", response_model=CoffeeReading)
async def upload_images(reading_id: str, files: List[UploadFile] = File(...)):
    r = _get(reading_id)

    if len(files) < settings.MIN_PHOTOS or len(files) > settings.MAX_PHOTOS:
        raise HTTPException(
            status_code=400,
            detail=f"Lütfen {settings.MIN_PHOTOS}-{settings.MAX_PHOTOS} arası foto yükle.",
        )

    saved = await save_uploads(reading_id, files)
    r.photos = saved
    r.status = "photos_uploaded"
    r.invalid_reason = None
    FAKE_DB[reading_id] = r
    return r

@router.post("/{reading_id}/validate-images", response_model=CoffeeReading)
async def validate_images(reading_id: str):
    r = _get(reading_id)
    if not r.photos:
        raise HTTPException(status_code=400, detail="No photos uploaded")

    res = validate_coffee_images(r.photos)
    if not res["ok"]:
        r.status = "invalid_photos"
        r.invalid_reason = res["reason"]
        FAKE_DB[reading_id] = r
        raise HTTPException(status_code=400, detail=f"Fotoğraflar uygun değil: {r.invalid_reason}")

    r.invalid_reason = None
    FAKE_DB[reading_id] = r
    return r

@router.post("/{reading_id}/mark-paid", response_model=CoffeeReading)
async def mark_paid(reading_id: str, body: MarkPaidRequest):
    r = _get(reading_id)
    r.is_paid = True
    r.payment_ref = body.payment_ref
    r.status = "paid"
    FAKE_DB[reading_id] = r
    return r

@router.post("/{reading_id}/generate", response_model=CoffeeReading)
async def generate(reading_id: str):
    r = _get(reading_id)

    if not r.photos:
        raise HTTPException(status_code=400, detail="No photos uploaded")
    if r.status == "invalid_photos":
        raise HTTPException(status_code=400, detail=f"Invalid photos: {r.invalid_reason}")
    if not r.is_paid:
        raise HTTPException(status_code=400, detail="Payment required before reading")

    # tekrar kontrol
    res = validate_coffee_images(r.photos)
    if not res["ok"]:
        r.status = "invalid_photos"
        r.invalid_reason = res["reason"]
        FAKE_DB[reading_id] = r
        raise HTTPException(status_code=400, detail=f"Fotoğraflar uygun değil: {r.invalid_reason}")

    r.status = "processing"
    FAKE_DB[reading_id] = r

    comment = generate_fortune(
        name=r.name,
        topic=r.topic,
        question=r.question,
        image_paths=r.photos,
        relationship_status=r.relationship_status,
        big_decision=r.big_decision,
    )

    r.comment = comment
    r.status = "completed"
    FAKE_DB[reading_id] = r
    return r

@router.get("/{reading_id}", response_model=CoffeeReading)
async def detail(reading_id: str):
    return _get(reading_id)

@router.post("/{reading_id}/rate", response_model=CoffeeReading)
async def rate(reading_id: str, req: RatingRequest):
    r = _get(reading_id)
    if req.rating < 1 or req.rating > 5:
        raise HTTPException(status_code=400, detail="Rating must be 1..5")
    r.rating = req.rating
    FAKE_DB[reading_id] = r
    return r

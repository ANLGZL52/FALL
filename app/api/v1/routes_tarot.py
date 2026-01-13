from __future__ import annotations

from datetime import datetime
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session

from app.db import get_session
from app.models.tarot_db import TarotReadingDB
from app.repositories import tarot_repo
from app.schemas.tarot import (
    TarotStartRequest,
    TarotSelectCardsRequest,
    TarotMarkPaidRequest,
    TarotRatingRequest,
    TarotReading,
)
from app.services.openai_service import generate_tarot_reading

router = APIRouter(prefix="/tarot", tags=["tarot"])


def _to_schema(r: TarotReadingDB) -> TarotReading:
    return TarotReading(
        id=r.id,
        topic=r.topic,
        question=r.question,
        name=r.name,
        age=r.age,
        spread_type=r.spread_type,
        selected_cards=r.get_cards(),
        status=r.status,
        result_text=r.result_text,
        rating=getattr(r, "rating", None),
        is_paid=r.is_paid,
        payment_ref=getattr(r, "payment_ref", None),
        created_at=r.created_at,
    )


def _get_or_404(session: Session, reading_id: str) -> TarotReadingDB:
    r = tarot_repo.get_reading(session, reading_id)
    if not r:
        raise HTTPException(status_code=404, detail="Reading not found")
    return r


def _wanted_count(spread_type: str) -> int:
    """
    Flutter enum: TarotSpreadType { three, six, twelve }
    Backend spread_type: "three" | "six" | "twelve"
    """
    st = (spread_type or "").strip().lower()
    if st == "three":
        return 3
    if st == "six":
        return 6
    if st == "twelve":
        return 12
    raise HTTPException(status_code=400, detail=f"Geçersiz spread_type: {spread_type}")


@router.post("/start", response_model=TarotReading)
async def start(req: TarotStartRequest, session: Session = Depends(get_session)):
    # spread_type kontrolü (hata erken patlasın)
    _wanted_count(req.spread_type)

    obj = TarotReadingDB(
        id=str(uuid4()),
        topic=req.topic,
        question=req.question,
        name=req.name,
        age=req.age,
        spread_type=req.spread_type,  # three/six/twelve
        cards_json="[]",
        status="pending_payment",
        is_paid=False,
        payment_ref=None,
        result_text=None,
        rating=None,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    obj = tarot_repo.create_reading(session, obj)
    return _to_schema(obj)


@router.post("/{reading_id}/select-cards", response_model=TarotReading)
async def select_cards(reading_id: str, req: TarotSelectCardsRequest, session: Session = Depends(get_session)):
    r = _get_or_404(session, reading_id)

    wanted = _wanted_count(r.spread_type)

    if len(req.cards) != wanted:
        raise HTTPException(status_code=400, detail=f"Bu açılım için {wanted} kart seçmelisin.")

    r = tarot_repo.set_cards(session, reading_id, req.cards)
    return _to_schema(r)


@router.post("/{reading_id}/mark-paid", response_model=TarotReading)
async def mark_paid(reading_id: str, body: TarotMarkPaidRequest, session: Session = Depends(get_session)):
    r = _get_or_404(session, reading_id)

    # ✅ payment_ref zorunlu (mock bile olsa)
    if not body.payment_ref or not body.payment_ref.strip():
        raise HTTPException(status_code=422, detail="payment_ref is required")

    if not r.get_cards():
        raise HTTPException(status_code=400, detail="Ödemeden önce kartlarını seçmelisin.")

    r.is_paid = True
    r.payment_ref = body.payment_ref.strip()
    r.status = "paid"
    r.updated_at = datetime.utcnow()
    r = tarot_repo.update_reading(session, r)
    return _to_schema(r)


@router.post("/{reading_id}/generate", response_model=TarotReading)
async def generate(reading_id: str, session: Session = Depends(get_session)):
    r = _get_or_404(session, reading_id)

    if not r.get_cards():
        raise HTTPException(status_code=400, detail="Önce kart seçmelisin.")

    # ✅ ödeme yoksa 402
    if not r.is_paid:
        raise HTTPException(status_code=402, detail="Payment Required")

    if r.status == "completed" and r.result_text:
        return _to_schema(r)

    tarot_repo.set_status(session, reading_id, "processing")

    try:
        cards = r.get_cards()
        text = generate_tarot_reading(
            name=r.name,
            age=r.age,
            topic=r.topic,
            question=r.question,
            spread_type=r.spread_type,
            selected_cards=cards,
        )
    except Exception as e:
        tarot_repo.set_status(session, reading_id, "paid")
        raise HTTPException(status_code=500, detail=f"Tarot yorum üretilemedi: {e}")

    r = tarot_repo.set_status(session, reading_id, "completed", result_text=text)
    return _to_schema(r)


@router.get("/{reading_id}", response_model=TarotReading)
async def detail(reading_id: str, session: Session = Depends(get_session)):
    r = _get_or_404(session, reading_id)
    return _to_schema(r)


@router.post("/{reading_id}/rate", response_model=TarotReading)
async def rate(reading_id: str, req: TarotRatingRequest, session: Session = Depends(get_session)):
    r = _get_or_404(session, reading_id)

    if req.rating < 1 or req.rating > 5:
        raise HTTPException(status_code=400, detail="Rating must be 1..5")

    r.rating = req.rating
    r.updated_at = datetime.utcnow()
    r = tarot_repo.update_reading(session, r)
    return _to_schema(r)

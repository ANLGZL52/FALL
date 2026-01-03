# app/api/v1/routes_birthchart.py
from __future__ import annotations

from uuid import uuid4
from typing import Any, Dict

from fastapi import APIRouter, HTTPException, Depends
from sqlmodel import Session

from app.db import get_session
from app.schemas.birthchart import BirthChartStartRequest
from app.repositories.birthchart_repo import birthchart_repo
from app.services.birthchart_service import generate_birthchart_reading

router = APIRouter(prefix="/birthchart", tags=["birthchart"])


@router.post("/start")
def start_birthchart(payload: BirthChartStartRequest, session: Session = Depends(get_session)):
    reading_id = str(uuid4())
    reading = birthchart_repo.create(
        session=session,
        reading_id=reading_id,
        name=payload.name,
        birth_date=payload.birth_date,
        birth_time=payload.birth_time,
        birth_city=payload.birth_city,
        birth_country=payload.birth_country,
        topic=payload.topic,
        question=payload.question,
    )
    return reading


@router.post("/{reading_id}/mark-paid")
def mark_paid(reading_id: str, payload: Dict[str, Any] | None = None, session: Session = Depends(get_session)):
    payment_ref = (payload or {}).get("payment_ref")
    reading = birthchart_repo.mark_paid(session=session, reading_id=reading_id, payment_ref=payment_ref)
    if not reading:
        raise HTTPException(status_code=404, detail="Reading not found")
    return reading


@router.post("/{reading_id}/generate")
def generate(reading_id: str, session: Session = Depends(get_session)):
    reading = birthchart_repo.get(session=session, reading_id=reading_id)
    if not reading:
        raise HTTPException(status_code=404, detail="Reading not found")

    if not reading.get("is_paid"):
        raise HTTPException(status_code=402, detail="Payment Required")

    birthchart_repo.set_status(session=session, reading_id=reading_id, status="processing")

    try:
        result_text = generate_birthchart_reading(
            name=reading.get("name") or "",
            birth_date=reading.get("birth_date") or "",
            birth_time=reading.get("birth_time"),
            birth_city=reading.get("birth_city") or "",
            birth_country=reading.get("birth_country") or "TR",
            topic=reading.get("topic") or "genel",
            question=reading.get("question"),
        )
        updated = birthchart_repo.set_result(session=session, reading_id=reading_id, result_text=result_text)
        return updated
    except Exception as e:
        birthchart_repo.set_status(session=session, reading_id=reading_id, status="paid")
        raise HTTPException(status_code=500, detail=f"Doğum haritası yorum üretilemedi: {e}")

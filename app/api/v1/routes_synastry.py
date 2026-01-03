# app/api/v1/routes_synastry.py
from __future__ import annotations

from uuid import uuid4
from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import Response
from sqlmodel import Session

from app.db import get_session
from app.schemas.synastry import SynastryStartRequest, SynastryMarkPaidRequest, SynastryRatingRequest
from app.repositories.synastry_repo import synastry_repo
from app.services.synastry_service import generate_synastry_reading
from app.services.pdf_service import build_synastry_pdf_bytes

router = APIRouter(prefix="/synastry", tags=["synastry"])


@router.post("/start")
def start(payload: SynastryStartRequest, session: Session = Depends(get_session)):
    reading_id = str(uuid4())
    reading = synastry_repo.create(
        session=session,
        reading_id=reading_id,
        name_a=payload.name_a,
        birth_date_a=payload.birth_date_a,
        birth_time_a=payload.birth_time_a,
        birth_city_a=payload.birth_city_a,
        birth_country_a=payload.birth_country_a,
        name_b=payload.name_b,
        birth_date_b=payload.birth_date_b,
        birth_time_b=payload.birth_time_b,
        birth_city_b=payload.birth_city_b,
        birth_country_b=payload.birth_country_b,
        topic=payload.topic,
        question=payload.question,
    )
    return reading


# ✅ STATUS ENDPOINT (Flutter polling bunu çağırıyor)
@router.get("/{reading_id}")
def get_status(reading_id: str, session: Session = Depends(get_session)):
    reading = synastry_repo.get(session=session, reading_id=reading_id)
    if not reading:
        raise HTTPException(status_code=404, detail="Reading not found")
    return reading


@router.post("/{reading_id}/mark-paid")
def mark_paid(
    reading_id: str,
    payload: SynastryMarkPaidRequest | None = None,
    session: Session = Depends(get_session),
):
    payment_ref = (payload.payment_ref if payload else None)
    reading = synastry_repo.mark_paid(session=session, reading_id=reading_id, payment_ref=payment_ref)
    if not reading:
        raise HTTPException(status_code=404, detail="Reading not found")
    return reading


@router.post("/{reading_id}/generate")
def generate(reading_id: str, session: Session = Depends(get_session)):
    reading = synastry_repo.get(session=session, reading_id=reading_id)
    if not reading:
        raise HTTPException(status_code=404, detail="Reading not found")

    if not reading.get("is_paid"):
        raise HTTPException(status_code=402, detail="Payment Required")

    synastry_repo.set_status(session=session, reading_id=reading_id, status="processing")

    try:
        result_text = generate_synastry_reading(
            name_a=reading.get("name_a") or "",
            birth_date_a=reading.get("birth_date_a") or "",
            birth_time_a=reading.get("birth_time_a"),
            birth_city_a=reading.get("birth_city_a") or "",
            birth_country_a=reading.get("birth_country_a") or "Türkiye",
            name_b=reading.get("name_b") or "",
            birth_date_b=reading.get("birth_date_b") or "",
            birth_time_b=reading.get("birth_time_b"),
            birth_city_b=reading.get("birth_city_b") or "",
            birth_country_b=reading.get("birth_country_b") or "Türkiye",
            topic=reading.get("topic") or "Genel",
            question=reading.get("question"),
        )
        updated = synastry_repo.set_result(session=session, reading_id=reading_id, result_text=result_text)
        return updated
    except Exception as e:
        synastry_repo.set_status(session=session, reading_id=reading_id, status="paid")
        raise HTTPException(status_code=500, detail=f"Synastry üretilemedi: {e}")


@router.post("/{reading_id}/rate")
def rate(reading_id: str, payload: SynastryRatingRequest, session: Session = Depends(get_session)):
    reading = synastry_repo.set_rating(session=session, reading_id=reading_id, rating=payload.rating)
    if not reading:
        raise HTTPException(status_code=404, detail="Reading not found")
    return reading


@router.get("/{reading_id}/pdf")
def download_pdf(reading_id: str, session: Session = Depends(get_session)):
    reading = synastry_repo.get(session=session, reading_id=reading_id)
    if not reading:
        raise HTTPException(status_code=404, detail="Reading not found")

    if not reading.get("result_text"):
        raise HTTPException(status_code=409, detail="Result not generated yet")

    pdf_bytes = build_synastry_pdf_bytes(
        title="Sinastri (Aşk Uyumu) Analizi",
        reading=reading,
    )

    filename = f"synastry_{reading_id}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )

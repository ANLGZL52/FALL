from __future__ import annotations

from uuid import uuid4

from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import Response
from sqlmodel import Session

from app.db import get_session
from app.schemas.personality import (
    PersonalityStartRequest,
    PersonalityMarkPaidRequest,
    PersonalityRatingRequest,
)
from app.repositories.personality_repo import personality_repo
from app.services.personality_service import generate_personality_reading
from app.services.pdf_service import build_personality_pdf_bytes

router = APIRouter(
    prefix="/personality",
    tags=["Personality"],
)


@router.post("/start")
def start_personality(
    payload: PersonalityStartRequest,
    session: Session = Depends(get_session),
):
    reading_id = str(uuid4())

    reading = personality_repo.create(
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
def mark_paid(
    reading_id: str,
    payload: PersonalityMarkPaidRequest | None = None,
    session: Session = Depends(get_session),
):
    """
    ✅ Legacy/mock akış bozulmasın diye endpoint duruyor.
    🔒 Ama güvenlik için sadece TEST-... (mock) ödeme ref ile çalışır.
    Real ödeme: /payments/verify server-side mark_paid yapar.
    """
    payment_ref = payload.payment_ref if payload else None

    if not payment_ref:
        raise HTTPException(status_code=422, detail="payment_ref is required")

    if not str(payment_ref).startswith("TEST-"):
        raise HTTPException(
            status_code=403,
            detail="mark-paid is legacy only. Use /payments/verify for real payments.",
        )

    reading = personality_repo.mark_paid(
        session=session,
        reading_id=reading_id,
        payment_ref=payment_ref,
    )
    if not reading:
        raise HTTPException(status_code=404, detail="Reading not found")
    return reading


@router.post("/{reading_id}/generate")
def generate_personality(
    reading_id: str,
    session: Session = Depends(get_session),
):
    reading = personality_repo.get(session=session, reading_id=reading_id)
    if not reading:
        raise HTTPException(status_code=404, detail="Reading not found")

    if not reading.get("is_paid"):
        raise HTTPException(status_code=402, detail="Payment Required")

    personality_repo.set_status(
        session=session,
        reading_id=reading_id,
        status="processing",
    )

    try:
        result_text = generate_personality_reading(
            name=reading.get("name") or "",
            birth_date=reading.get("birth_date") or "",
            birth_time=reading.get("birth_time"),
            birth_city=reading.get("birth_city") or "",
            birth_country=reading.get("birth_country") or "TR",
            topic=reading.get("topic") or "genel",
            question=reading.get("question"),
        )

        updated = personality_repo.set_result(
            session=session,
            reading_id=reading_id,
            result_text=result_text,
        )
        return updated

    except Exception as e:
        personality_repo.set_status(
            session=session,
            reading_id=reading_id,
            status="paid",
        )
        raise HTTPException(
            status_code=500,
            detail=f"Kişilik analizi üretilemedi: {e}",
        )


@router.post("/{reading_id}/rate")
def rate_personality(
    reading_id: str,
    payload: PersonalityRatingRequest,
    session: Session = Depends(get_session),
):
    reading = personality_repo.set_rating(
        session=session,
        reading_id=reading_id,
        rating=payload.rating,
    )
    if not reading:
        raise HTTPException(status_code=404, detail="Reading not found")
    return reading


@router.get("/{reading_id}/pdf")
def download_personality_pdf(
    reading_id: str,
    session: Session = Depends(get_session),
):
    reading = personality_repo.get(session=session, reading_id=reading_id)
    if not reading:
        raise HTTPException(status_code=404, detail="Reading not found")

    if not reading.get("result_text"):
        raise HTTPException(status_code=409, detail="Result not generated yet")

    pdf_bytes = build_personality_pdf_bytes(
        title="Kişilik Analizi (Numeroloji + Doğum Haritası)",
        name=reading.get("name") or "",
        birth_date=reading.get("birth_date") or "",
        birth_time=reading.get("birth_time"),
        birth_city=reading.get("birth_city") or "",
        birth_country=reading.get("birth_country") or "TR",
        topic=reading.get("topic") or "genel",
        question=reading.get("question"),
        result_text=reading.get("result_text") or "",
    )

    filename = f"personality_{reading_id}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"'
        },
    )

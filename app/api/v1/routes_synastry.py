# app/api/v1/routes_synastry.py
from __future__ import annotations

from uuid import uuid4
from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import Response
from sqlmodel import Session

from app.db import get_session
from app.schemas.synastry import SynastryStartRequest, SynastryMarkPaidRequest, SynastryRatingRequest
from app.repositories.synastry_repo import synastry_repo

# Not: sende generate_synastry_reading hangi modüldeyse orası kalsın.
# Ben burada senin kullandığın importu bozmuyorum:
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
    """
    ✅ Legacy/mock akış bozulmasın diye endpoint duruyor.
    🔒 Ama güvenlik için sadece TEST-... (mock) ödeme ref ile çalışır.
    Real ödeme: /payments/verify server-side mark_paid yapar.
    """
    payment_ref = (payload.payment_ref if payload else None)

    if not payment_ref:
        raise HTTPException(status_code=422, detail="payment_ref is required")

    if not str(payment_ref).startswith("TEST-"):
        raise HTTPException(
            status_code=403,
            detail="mark-paid is legacy only. Use /payments/verify for real payments.",
        )

    reading = synastry_repo.mark_paid(session=session, reading_id=reading_id, payment_ref=payment_ref)
    if not reading:
        raise HTTPException(status_code=404, detail="Reading not found")
    return reading


@router.post("/{reading_id}/generate")
def generate(reading_id: str, session: Session = Depends(get_session)):
    """
    ✅ İdempotent + race-safe generate:
    - done ise: mevcut sonucu döndür (tekrar OpenAI yok)
    - processing ise: mevcut state'i döndür (tekrar OpenAI yok)
    - paid ise: processing'e claim et ve 1 kez üret
    """
    # 1) claim
    reading, claimed = synastry_repo.claim_processing(session=session, reading_id=reading_id)
    if not reading:
        raise HTTPException(status_code=404, detail="Reading not found")

    # 2) ödeme kontrolü
    if not reading.get("is_paid"):
        raise HTTPException(status_code=402, detail="Payment Required")

    # 3) zaten done ise hemen dön
    if (reading.get("result_text") or "").strip():
        return reading

    # 4) processing ama bu request claim etmediyse tekrar üretme
    if (reading.get("status") or "").lower().strip() == "processing" and not claimed:
        # burada 200 dönüyoruz; Flutter zaten poll ediyor.
        return reading

    # 5) Bu request processing'i claim ettiyse üret
    try:
        result_text = generate_synastry_reading(
            name_a=reading.get("name_a") or "",
            birth_date_a=reading.get("birth_date_a") or "",
            birth_time_a=reading.get("birth_time_a"),
            birth_city_a=reading.get("birth_city_a") or "",
            birth_country_a=reading.get("birth_country_a") or "TR",
            name_b=reading.get("name_b") or "",
            birth_date_b=reading.get("birth_date_b") or "",
            birth_time_b=reading.get("birth_time_b"),
            birth_city_b=reading.get("birth_city_b") or "",
            birth_country_b=reading.get("birth_country_b") or "TR",
            topic=reading.get("topic") or "Genel",
            question=reading.get("question"),
        )
        updated = synastry_repo.set_result(session=session, reading_id=reading_id, result_text=result_text)
        return updated
    except Exception as e:
        # hata olursa paid'e geri al (yeniden generate denenebilsin)
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

    if not (reading.get("result_text") or "").strip():
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

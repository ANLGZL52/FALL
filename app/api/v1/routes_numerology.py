# app/api/v1/routes_numerology.py
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session

from app.db import get_session
from app.schemas.numerology import NumerologyStartIn, NumerologyReadingOut, MarkPaidIn
from app.repositories.numerology_repo import NumerologyRepo
from app.services.openai_service import generate_numerology_reading

router = APIRouter(prefix="/numerology", tags=["numerology"])
_repo = NumerologyRepo()


@router.post("/start", response_model=NumerologyReadingOut)
def start(payload: NumerologyStartIn, session: Session = Depends(get_session)):
    try:
        created = _repo.create(
            session=session,
            name=payload.name,
            birth_date=payload.birth_date,
            topic=payload.topic,
            question=payload.question,
        )
        if not created:
            raise HTTPException(status_code=500, detail="Numerology kayıt oluşturulamadı.")
        return created
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Numerology start failed: {e}")


@router.get("/{reading_id}", response_model=NumerologyReadingOut)
def get_reading(reading_id: str, session: Session = Depends(get_session)):
    obj = _repo.get(session=session, reading_id=reading_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Numerology kaydı bulunamadı.")
    return obj


@router.post("/{reading_id}/mark-paid", response_model=NumerologyReadingOut)
def mark_paid(reading_id: str, payload: MarkPaidIn, session: Session = Depends(get_session)):
    """
    ✅ Legacy/mock akış bozulmasın diye endpoint duruyor.
    🔒 Sadece TEST-... (mock) ödeme ref ile çalışır.
    Real ödeme: /payments/verify server-side unlock/mark_paid yapar.
    """
    if not payload.payment_ref:
        raise HTTPException(status_code=422, detail="payment_ref is required")

    if not str(payload.payment_ref).startswith("TEST-"):
        raise HTTPException(
            status_code=403,
            detail="mark-paid is legacy only. Use /payments/verify for real payments.",
        )

    obj = _repo.mark_paid(session=session, reading_id=reading_id, payment_ref=payload.payment_ref)
    if not obj:
        raise HTTPException(status_code=404, detail="Numerology kaydı bulunamadı (mark-paid).")
    return obj


@router.post("/{reading_id}/generate", response_model=NumerologyReadingOut)
def generate(reading_id: str, session: Session = Depends(get_session)):
    obj = _repo.get(session=session, reading_id=reading_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Numerology kaydı bulunamadı (generate).")

    # 🔒 Ödeme zorunlu
    if not bool(obj.get("is_paid", False)):
        raise HTTPException(status_code=402, detail="Payment Required")

    status = (obj.get("status") or "").lower().strip()
    result_text = (obj.get("result_text") or "").strip()

    # ✅ idempotent: sonuç varsa direkt dön
    if result_text and status == "done":
        return obj

    # ✅ processing ise tekrar üretme
    if status == "processing":
        return obj

    # ✅ paid değilse (started vs) zorla paid'e çekmeyelim; ama ödeme varsa paid olmalı
    # Yine de güvenli olsun:
    if status not in ("paid", "processing", "done"):
        _repo.set_status(session=session, reading_id=reading_id, status="paid")
        obj = _repo.get(session=session, reading_id=reading_id) or obj
        status = (obj.get("status") or "").lower().strip()

    # ✅ processing’e çek (generate kilidi)
    _repo.set_status(session=session, reading_id=reading_id, status="processing")

    try:
        text = generate_numerology_reading(
            name=obj.get("name", ""),
            birth_date=obj.get("birth_date", ""),
            topic=obj.get("topic", "genel"),
            question=obj.get("question"),
        )

        updated = _repo.set_result(session=session, reading_id=reading_id, result_text=text)
        if not updated:
            # burada status’u paid’e çekip fail
            _repo.set_status(session=session, reading_id=reading_id, status="paid")
            raise HTTPException(status_code=500, detail="AI sonucu DB'ye yazılamadı.")
        return updated

    except HTTPException:
        # ✅ hata olursa paid'e geri al ki tekrar deneme mümkün olsun
        _repo.set_status(session=session, reading_id=reading_id, status="paid")
        raise
    except Exception as e:
        _repo.set_status(session=session, reading_id=reading_id, status="paid")
        raise HTTPException(status_code=500, detail=f"Numerology yorum üretilemedi: {e}")

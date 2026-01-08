from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.schemas.numerology import NumerologyStartIn, NumerologyReadingOut, MarkPaidIn
from app.repositories.numerology_repo import NumerologyRepo
from app.services.openai_service import generate_numerology_reading

router = APIRouter(prefix="/numerology", tags=["numerology"])
_repo = NumerologyRepo()


def _make_get_db():
    try:
        from app.db import SessionLocal  # type: ignore

        def get_db():
            db = SessionLocal()
            try:
                yield db
            finally:
                db.close()

        return get_db
    except Exception:
        pass

    try:
        from app.db import get_db as get_db_dep  # type: ignore
        return get_db_dep
    except Exception:
        pass

    try:
        from app.db import get_session as get_session_dep  # type: ignore
        return get_session_dep
    except Exception:
        pass

    raise RuntimeError(
        "DB dependency bulunamadı. app/db.py içinde SessionLocal veya get_db veya get_session olmalı."
    )


get_db = _make_get_db()


@router.post("/start", response_model=NumerologyReadingOut)
def start(payload: NumerologyStartIn, db: Session = Depends(get_db)):
    try:
        created = _repo.create(
            session=db,
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
def get_reading(reading_id: str, db: Session = Depends(get_db)):
    obj = _repo.get(session=db, reading_id=reading_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Numerology kaydı bulunamadı.")
    return obj


@router.post("/{reading_id}/mark-paid", response_model=NumerologyReadingOut)
def mark_paid(reading_id: str, payload: MarkPaidIn, db: Session = Depends(get_db)):
    # Şimdilik kullanılmıyor ama endpoint dursun
    obj = _repo.mark_paid(session=db, reading_id=reading_id, payment_ref=payload.payment_ref)
    if not obj:
        raise HTTPException(status_code=404, detail="Numerology kaydı bulunamadı (mark-paid).")
    return obj


@router.post("/{reading_id}/generate", response_model=NumerologyReadingOut)
def generate(reading_id: str, db: Session = Depends(get_db)):
    obj = _repo.get(session=db, reading_id=reading_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Numerology kaydı bulunamadı (generate).")

    # ✅ Ödeme zorunluluğu kaldırıldı (mock/şimdilik ödeme yok akışı)
    # if not obj.get("is_paid", False):
    #     raise HTTPException(status_code=402, detail="Ödeme yapılmadan AI yorumu üretilemez.")

    if (obj.get("result_text") or "").strip():
        return obj

    try:
        text = generate_numerology_reading(
            name=obj.get("name", ""),
            birth_date=obj.get("birth_date", ""),
            topic=obj.get("topic", "genel"),
            question=obj.get("question"),
        )

        updated = _repo.set_result(session=db, reading_id=reading_id, result_text=text)
        if not updated:
            raise HTTPException(status_code=500, detail="AI sonucu DB'ye yazılamadı.")
        return updated

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Numerology yorum üretilemedi: {e}")

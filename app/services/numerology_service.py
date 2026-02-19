from __future__ import annotations

from typing import Optional, Dict, Any
from sqlalchemy.orm import Session

from app.repositories.numerology_repo import NumerologyRepo
from app.services.openai_service import generate_numerology_reading

repo = NumerologyRepo()


def start_reading(
    *,
    session: Session,
    name: str,
    birth_date: str,
    topic: str,
    question: Optional[str] = None,
) -> Dict[str, Any]:
    return repo.create(
        session=session,
        name=name,
        birth_date=birth_date,
        topic=topic,
        question=question,
    )


def mark_paid(*, session: Session, reading_id: str, payment_ref: Optional[str]) -> Dict[str, Any]:
    obj = repo.mark_paid(session=session, reading_id=reading_id, payment_ref=payment_ref)
    if not obj:
        raise RuntimeError("Numerology kaydı bulunamadı (mark_paid).")
    return obj


def generate(*, session: Session, reading_id: str) -> Dict[str, Any]:
    obj = repo.get(session=session, reading_id=reading_id)
    if not obj:
        raise RuntimeError("Numerology kaydı bulunamadı (generate).")

    # ✅ Ödeme zorunluluğu kaldırıldı
    # if not obj.get("is_paid", False):
    #     raise RuntimeError("Ödeme yapılmadan AI yorumu üretilemez.")

    if (obj.get("result_text") or "").strip():
        return obj

    text = generate_numerology_reading(
        name=obj.get("name", ""),
        birth_date=obj.get("birth_date", ""),
        topic=obj.get("topic", "genel"),
        question=obj.get("question"),
    )

    updated = repo.set_result(session=session, reading_id=reading_id, result_text=text)
    if not updated:
        raise RuntimeError("AI sonucu DB'ye yazılamadı.")
    return updated

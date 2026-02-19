# app/services/personality_background.py
from __future__ import annotations

from sqlmodel import Session

from app.repositories.personality_repo import personality_repo
from app.services.personality_service import generate_personality_reading


def _get_session_factory():
    """
    app/db.py içinde genelde SessionLocal vardır.
    Yoksa engine üzerinden Session(engine) ile açar.
    """
    try:
        from app.db import SessionLocal  # type: ignore
        return SessionLocal
    except Exception:
        pass

    try:
        from app.db import engine  # type: ignore

        def _factory():
            return Session(engine)

        return _factory
    except Exception as e:
        raise RuntimeError(
            "DB session factory bulunamadı. app/db.py içinde SessionLocal veya engine olmalı."
        ) from e


def run_personality_generation(reading_id: str) -> None:
    """
    Background task:
    - reading'i çek
    - ödeme yoksa çık
    - OpenAI üret
    - result_text yaz + status=done
    - hata olursa status=paid'e geri çek
    """
    session_factory = _get_session_factory()

    with session_factory() as session:
        reading = personality_repo.get(session=session, reading_id=reading_id)
        if not reading:
            return

        if not reading.get("is_paid"):
            return

        status = (reading.get("status") or "").lower().strip()
        result_text = (reading.get("result_text") or "").strip()

        # idempotent: zaten done ise çık
        if status == "done" and result_text:
            return

        # processing'e çek
        personality_repo.set_status(session=session, reading_id=reading_id, status="processing")

        try:
            result = generate_personality_reading(
                name=reading.get("name") or "",
                birth_date=reading.get("birth_date") or "",
                birth_time=reading.get("birth_time"),
                birth_city=reading.get("birth_city") or "",
                birth_country=reading.get("birth_country") or "TR",
                topic=reading.get("topic") or "genel",
                question=reading.get("question"),
            )

            personality_repo.set_result(session=session, reading_id=reading_id, result_text=result)
            personality_repo.set_status(session=session, reading_id=reading_id, status="done")

        except Exception:
            # kullanıcı tekrar deneyebilsin
            personality_repo.set_status(session=session, reading_id=reading_id, status="paid")

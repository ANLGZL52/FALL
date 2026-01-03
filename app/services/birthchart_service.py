# app/services/birthchart_service.py
from __future__ import annotations

from typing import Optional

from app.services.openai_service import generate_birthchart_reading as _generate_birthchart_reading


def generate_birthchart_reading(
    *,
    name: str,
    birth_date: str,
    birth_time: Optional[str],
    birth_city: str,
    birth_country: str,
    topic: str,
    question: Optional[str] = None,
) -> str:
    return _generate_birthchart_reading(
        name=name,
        birth_date=birth_date,
        birth_time=birth_time,
        birth_city=birth_city,
        birth_country=birth_country,
        topic=topic,
        question=question,
    )

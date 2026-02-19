from __future__ import annotations

from typing import Optional

from app.services.openai_service import generate_synastry_reading as _generate_synastry_reading


def generate_synastry_reading(
    *,
    name_a: str,
    birth_date_a: str,
    birth_time_a: Optional[str],
    birth_city_a: str,
    birth_country_a: str,
    name_b: str,
    birth_date_b: str,
    birth_time_b: Optional[str],
    birth_city_b: str,
    birth_country_b: str,
    topic: str,
    question: Optional[str] = None,
) -> str:
    return _generate_synastry_reading(
        name_a=name_a,
        birth_date_a=birth_date_a,
        birth_time_a=birth_time_a,
        birth_city_a=birth_city_a,
        birth_country_a=birth_country_a,
        name_b=name_b,
        birth_date_b=birth_date_b,
        birth_time_b=birth_time_b,
        birth_city_b=birth_city_b,
        birth_country_b=birth_country_b,
        topic=topic,
        question=question,
    )

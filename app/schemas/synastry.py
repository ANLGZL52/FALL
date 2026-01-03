from __future__ import annotations

from pydantic import BaseModel, Field
from typing import Optional


class SynastryStartRequest(BaseModel):
    # Partner A
    name_a: str = Field(min_length=1)
    birth_date_a: str  # YYYY-MM-DD
    birth_time_a: Optional[str] = None
    birth_city_a: str = Field(min_length=1)
    birth_country_a: str = "TR"

    # Partner B
    name_b: str = Field(min_length=1)
    birth_date_b: str  # YYYY-MM-DD
    birth_time_b: Optional[str] = None
    birth_city_b: str = Field(min_length=1)
    birth_country_b: str = "TR"

    topic: str = "genel"
    question: Optional[str] = None


class SynastryMarkPaidRequest(BaseModel):
    payment_ref: Optional[str] = None


class SynastryRatingRequest(BaseModel):
    rating: int = Field(ge=1, le=5)

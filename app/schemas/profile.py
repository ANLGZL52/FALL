from __future__ import annotations

from typing import Optional
from pydantic import BaseModel, Field


class ProfileUpsertRequest(BaseModel):
    display_name: str = Field(default="Misafir", max_length=80)
    birth_date: Optional[str] = Field(default=None, max_length=10)   # YYYY-MM-DD
    birth_place: Optional[str] = Field(default=None, max_length=120)
    birth_time: Optional[str] = Field(default=None, max_length=5)    # HH:MM


class ProfileResponse(BaseModel):
    device_id: str
    display_name: str
    birth_date: Optional[str] = None
    birth_place: Optional[str] = None
    birth_time: Optional[str] = None

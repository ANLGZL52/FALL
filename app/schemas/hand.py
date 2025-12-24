# app/schemas/hand.py
from __future__ import annotations
from typing import List, Optional
from pydantic import BaseModel


class HandValidateResponse(BaseModel):
    ok: bool
    reason: str


class HandAnalyzeResponse(BaseModel):
    reading_id: int
    ai_result: str

# app/api/v1/routes_hand.py
from __future__ import annotations

from typing import List, Optional
from fastapi import APIRouter, Depends, File, Form, UploadFile, HTTPException
from sqlmodel import Session

from app.db import get_session
from app.schemas.hand import HandValidateResponse, HandAnalyzeResponse
from app.services.hand_service import HandService

router = APIRouter(prefix="/hand", tags=["hand"])
service = HandService()


@router.post("/validate", response_model=HandValidateResponse)
async def validate_hand(file: UploadFile = File(...)):
    if not file:
        raise HTTPException(status_code=400, detail="Dosya yok.")
    result = await service.validate_before_payment(file)
    return HandValidateResponse(**result)


@router.post("/analyze", response_model=HandAnalyzeResponse)
async def analyze_hand(
    session: Session = Depends(get_session),
    files: List[UploadFile] = File(...),

    topic: str = Form("Genel"),
    focus_text: str = Form(""),
    name: Optional[str] = Form(None),
    age: Optional[int] = Form(None),

    # şimdilik mock: frontend ödeme tamam diyince paid göndersin
    payment_status: str = Form("paid"),
):
    if not files or len(files) == 0:
        raise HTTPException(status_code=400, detail="En az 1 el fotoğrafı yüklemelisin.")

    if payment_status != "paid":
        raise HTTPException(status_code=402, detail="Ödeme tamamlanmadı.")

    reading = await service.analyze_after_payment(
        session=session,
        files=files,
        topic=topic,
        focus_text=focus_text,
        name=name,
        age=age,
        payment_status=payment_status,
    )

    return HandAnalyzeResponse(reading_id=reading.id, ai_result=reading.ai_result or "")

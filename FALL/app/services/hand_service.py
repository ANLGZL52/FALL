# app/services/hand_service.py
from __future__ import annotations

from typing import List, Optional
from fastapi import UploadFile
from sqlmodel import Session

from app.models.hand_db import HandReading
from app.repositories.hand_repo import HandRepo
from app.services.storage import StorageService
from app.services.openai_service import OpenAIService


class HandService:
    def __init__(
        self,
        repo: HandRepo | None = None,
        storage: StorageService | None = None,
        openai: OpenAIService | None = None,
    ):
        self.repo = repo or HandRepo()
        self.storage = storage or StorageService()
        self.openai = openai or OpenAIService()

    async def validate_before_payment(self, file: UploadFile) -> dict:
        image_bytes = await file.read()
        return self.openai.validate_hand_image(image_bytes, filename=file.filename)

    async def analyze_after_payment(
        self,
        session: Session,
        files: List[UploadFile],
        topic: str,
        focus_text: str,
        name: Optional[str],
        age: Optional[int],
        payment_status: str = "paid",
    ) -> HandReading:
        # kaydet
        saved_paths = []
        images_for_ai: List[tuple[bytes, str | None]] = []

        for f in files:
            img_bytes = await f.read()
            images_for_ai.append((img_bytes, f.filename))
            # tekrar oku yok; bytes zaten elimizde -> storage.save_bytes kullan
            path = self.storage.save_bytes(img_bytes, subdir="hand", suffix=("." + (f.filename.split(".")[-1].lower()) if f.filename and "." in f.filename else ".jpg"))
            saved_paths.append(str(path))

        # AI yorum
        ai_text = self.openai.generate_hand_reading(
            images=images_for_ai,
            topic=topic,
            focus_text=focus_text,
            name=name,
            age=age,
        )

        reading = HandReading(
            topic=topic,
            focus_text=focus_text or "",
            name=name,
            age=age,
            image_paths=";".join(saved_paths),
            payment_status=payment_status,
            ai_result=ai_text,
        )

        return self.repo.create(session, reading)

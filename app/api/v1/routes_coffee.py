# app/api/v1/routes_coffee.py
from __future__ import annotations

import os
import json
from typing import List
from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel

from app.core.config import settings
from app.services.storage import save_uploads, delete_reading_uploads
from app.services.openai_service import OpenAIService

# DB tarafın sende nasıl ise aynı kalsın diye:
from app.db.session import get_session
from app.models.coffee_db import CoffeeReadingDB


router = APIRouter(prefix="/coffee", tags=["coffee"])


class CoffeeStartIn(BaseModel):
    name: str
    age: int | None = None
    topic: str
    question: str


class MarkPaidIn(BaseModel):
    payment_ref: str


class RateIn(BaseModel):
    rating: int


@router.post("/start")
def start_reading(payload: CoffeeStartIn):
    session = get_session()
    try:
        rid = CoffeeReadingDB.create_new_id()  # sende yoksa alttaki gibi yap:
        # rid = str(uuid.uuid4())

        reading = CoffeeReadingDB(
            id=rid,
            topic=payload.topic,
            question=payload.question,
            name=payload.name,
            age=payload.age,
            images_json="[]",
            result_text=None,
            status="created",
            is_paid=False,
            payment_ref=None,
            rating=None,
        )
        session.add(reading)
        session.commit()
        session.refresh(reading)
        return reading.to_dict()
    except Exception as e:
        session.rollback()
        raise
    finally:
        session.close()


@router.post("/{reading_id}/upload-images")
async def upload_images(reading_id: str, files: List[UploadFile] = File(...)):
    if len(files) < settings.MIN_PHOTOS or len(files) > settings.MAX_PHOTOS:
        raise HTTPException(
            status_code=400,
            detail=f"Foto sayısı {settings.MIN_PHOTOS}-{settings.MAX_PHOTOS} aralığında olmalı."
        )

    session = get_session()
    try:
        reading = session.get(CoffeeReadingDB, reading_id)
        if not reading:
            raise HTTPException(404, "reading not found")

        saved = await save_uploads(reading_id=reading_id, files=files)

        # DB'ye kaydet
        reading.images_json = json.dumps(saved, ensure_ascii=False)
        reading.status = "images_uploaded"
        session.commit()
        session.refresh(reading)
        return reading.to_dict()

    except HTTPException:
        raise
    except Exception as e:
        session.rollback()
        raise
    finally:
        session.close()


@router.post("/{reading_id}/mark-paid")
def mark_paid(reading_id: str, payload: MarkPaidIn):
    session = get_session()
    try:
        reading = session.get(CoffeeReadingDB, reading_id)
        if not reading:
            raise HTTPException(404, "reading not found")

        reading.is_paid = True
        reading.payment_ref = payload.payment_ref
        reading.status = "paid"
        session.commit()
        session.refresh(reading)
        return reading.to_dict()
    finally:
        session.close()


@router.post("/{reading_id}/generate")
def generate(reading_id: str):
    session = get_session()
    try:
        reading = session.get(CoffeeReadingDB, reading_id)
        if not reading:
            raise HTTPException(404, "reading not found")

        if not reading.is_paid:
            raise HTTPException(403, "Not paid")

        images_list = json.loads(reading.images_json or "[]")  # saved paths
        if not images_list:
            raise HTTPException(400, "No images uploaded")

        # storage'dan byte oku
        images_bytes = []
        for item in images_list:
            path = item.get("path") or item.get("filepath")
            fname = item.get("filename")
            if not path or not os.path.exists(path):
                continue
            with open(path, "rb") as f:
                images_bytes.append((f.read(), fname))

        if not images_bytes:
            raise HTTPException(400, "Image files missing on disk")

        ai = OpenAIService()

        text = ai.generate_coffee_reading(
            images=images_bytes,
            topic=reading.topic,
            focus_text=reading.question,   # ✅ artık uyumlu
            name=reading.name,
            age=reading.age,
        )

        reading.result_text = text
        reading.status = "done"
        session.commit()
        session.refresh(reading)
        return reading.to_dict()

    finally:
        session.close()


@router.get("/{reading_id}")
def detail(reading_id: str):
    session = get_session()
    try:
        reading = session.get(CoffeeReadingDB, reading_id)
        if not reading:
            raise HTTPException(404, "reading not found")
        return reading.to_dict()
    finally:
        session.close()


@router.post("/{reading_id}/rate")
def rate(reading_id: str, payload: RateIn):
    if payload.rating < 1 or payload.rating > 5:
        raise HTTPException(400, "rating must be 1-5")

    session = get_session()
    try:
        reading = session.get(CoffeeReadingDB, reading_id)
        if not reading:
            raise HTTPException(404, "reading not found")
        reading.rating = payload.rating
        session.commit()
        session.refresh(reading)
        return reading.to_dict()
    finally:
        session.close()

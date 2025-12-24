# app/repositories/hand_repo.py
from __future__ import annotations

from sqlmodel import Session, select
from app.models.hand_db import HandReading


class HandRepo:
    def create(self, session: Session, reading: HandReading) -> HandReading:
        session.add(reading)
        session.commit()
        session.refresh(reading)
        return reading

    def get(self, session: Session, reading_id: int) -> HandReading | None:
        return session.exec(select(HandReading).where(HandReading.id == reading_id)).first()

    def update(self, session: Session, reading: HandReading) -> HandReading:
        session.add(reading)
        session.commit()
        session.refresh(reading)
        return reading

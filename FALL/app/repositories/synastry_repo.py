from __future__ import annotations

from datetime import datetime
from typing import Optional, Dict, Any, Tuple

from sqlmodel import Session, select

from app.models.synastry_db import SynastryReadingDB


class SynastryRepo:
    def create(
        self,
        *,
        session: Session,
        device_id: Optional[str],
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
        question: Optional[str],
    ) -> Dict[str, Any]:
        row = SynastryReadingDB(
            device_id=device_id,

            name_a=name_a or "",
            birth_date_a=birth_date_a or "",
            birth_time_a=birth_time_a,
            birth_city_a=birth_city_a or "",
            birth_country_a=birth_country_a or "TR",

            name_b=name_b or "",
            birth_date_b=birth_date_b or "",
            birth_time_b=birth_time_b,
            birth_city_b=birth_city_b or "",
            birth_country_b=birth_country_b or "TR",

            topic=topic or "genel",
            question=question,

            status="started",
            is_paid=False,
            payment_ref=None,
            result_text=None,
            rating=None,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )

        session.add(row)
        session.commit()
        session.refresh(row)
        return row.model_dump()

    def get(self, *, session: Session, reading_id: str) -> Optional[Dict[str, Any]]:
        stmt = select(SynastryReadingDB).where(SynastryReadingDB.id == reading_id)
        row = session.exec(stmt).first()
        return row.model_dump() if row else None

    def _get_row(self, *, session: Session, reading_id: str) -> Optional[SynastryReadingDB]:
        stmt = select(SynastryReadingDB).where(SynastryReadingDB.id == reading_id)
        return session.exec(stmt).first()

    def mark_paid(
        self,
        *,
        session: Session,
        reading_id: str,
        payment_ref: Optional[str],
    ) -> Optional[Dict[str, Any]]:
        row = self._get_row(session=session, reading_id=reading_id)
        if not row:
            return None

        row.is_paid = True
        row.payment_ref = payment_ref
        row.status = "paid"
        row.updated_at = datetime.utcnow()

        session.add(row)
        session.commit()
        session.refresh(row)
        return row.model_dump()

    def claim_processing(self, *, session: Session, reading_id: str) -> Tuple[Optional[Dict[str, Any]], bool]:
        """
        - result_text varsa: done'a çek, claimed=False
        - status=processing ise: claimed=False
        - is_paid ise: processing'e çek, claimed=True
        """
        row = self._get_row(session=session, reading_id=reading_id)
        if not row:
            return None, False

        if (row.result_text or "").strip():
            if (row.status or "").lower().strip() != "done":
                row.status = "done"
                row.updated_at = datetime.utcnow()
                session.add(row)
                session.commit()
                session.refresh(row)
            return row.model_dump(), False

        st = (row.status or "").lower().strip()
        if st == "processing":
            return row.model_dump(), False

        if row.is_paid:
            row.status = "processing"
            row.updated_at = datetime.utcnow()
            session.add(row)
            session.commit()
            session.refresh(row)
            return row.model_dump(), True

        return row.model_dump(), False

    def set_status(self, *, session: Session, reading_id: str, status: str) -> Optional[Dict[str, Any]]:
        row = self._get_row(session=session, reading_id=reading_id)
        if not row:
            return None
        row.status = status
        row.updated_at = datetime.utcnow()
        session.add(row)
        session.commit()
        session.refresh(row)
        return row.model_dump()

    def set_result(self, *, session: Session, reading_id: str, result_text: str) -> Optional[Dict[str, Any]]:
        row = self._get_row(session=session, reading_id=reading_id)
        if not row:
            return None
        row.result_text = result_text
        row.status = "done"
        row.updated_at = datetime.utcnow()
        session.add(row)
        session.commit()
        session.refresh(row)
        return row.model_dump()

    def set_rating(self, *, session: Session, reading_id: str, rating: int) -> Optional[Dict[str, Any]]:
        row = self._get_row(session=session, reading_id=reading_id)
        if not row:
            return None
        row.rating = rating
        row.updated_at = datetime.utcnow()
        session.add(row)
        session.commit()
        session.refresh(row)
        return row.model_dump()


synastry_repo = SynastryRepo()

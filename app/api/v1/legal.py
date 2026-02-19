# app/api/v1/legal.py
"""Yasal metin onayı: Kullanıcı Sözleşmesi onayı PostgreSQL'e kaydedilir."""
from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlmodel import Session, select

from app.core.device import get_device_id
from app.db import get_session
from app.models.legal_consent_db import LegalConsentDB

router = APIRouter(prefix="/legal", tags=["legal"])

DOCUMENT_TYPE_TERMS = "terms"


class LegalConsentRequest(BaseModel):
    document_type: str = DOCUMENT_TYPE_TERMS
    document_version: str | None = None


class LegalConsentRecord(BaseModel):
    document_type: str
    document_version: str | None
    accepted_at: datetime


class LegalConsentStatusResponse(BaseModel):
    accepted: bool
    accepted_at: datetime | None = None
    document_type: str


@router.post("/consent", response_model=LegalConsentRecord)
def record_consent(
    body: LegalConsentRequest,
    device_id: str = Depends(get_device_id),
    session: Session = Depends(get_session),
):
    """Kullanıcı yasal metni (Kullanıcı Sözleşmesi) onayladığında çağrılır. PostgreSQL'e kaydedilir."""
    doc_type = (body.document_type or DOCUMENT_TYPE_TERMS).strip() or DOCUMENT_TYPE_TERMS
    version = body.document_version.strip() if body.document_version else None

    record = LegalConsentDB(
        device_id=device_id,
        document_type=doc_type,
        document_version=version,
    )
    session.add(record)
    session.commit()
    session.refresh(record)

    return LegalConsentRecord(
        document_type=record.document_type,
        document_version=record.document_version,
        accepted_at=record.accepted_at,
    )


@router.get("/consent/status", response_model=LegalConsentStatusResponse)
def get_consent_status(
    document_type: str = Query(default=DOCUMENT_TYPE_TERMS, description="terms, privacy, disclaimer"),
    device_id: str = Depends(get_device_id),
    session: Session = Depends(get_session),
):
    """Bu cihaz (device_id) için belirtilen yasal metnin onaylanıp onaylanmadığını döner."""
    doc_type = (document_type or DOCUMENT_TYPE_TERMS).strip() or DOCUMENT_TYPE_TERMS

    stmt = select(LegalConsentDB).where(
        LegalConsentDB.device_id == device_id,
        LegalConsentDB.document_type == doc_type,
    ).order_by(LegalConsentDB.accepted_at.desc()).limit(1)

    row = session.exec(stmt).first()

    if row is None:
        return LegalConsentStatusResponse(accepted=False, accepted_at=None, document_type=doc_type)

    return LegalConsentStatusResponse(
        accepted=True,
        accepted_at=row.accepted_at,
        document_type=row.document_type,
    )

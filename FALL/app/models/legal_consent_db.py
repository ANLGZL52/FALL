# app/models/legal_consent_db.py
"""Yasal metin (Kullanıcı Sözleşmesi) onay kayıtları - PostgreSQL'de saklanır."""
from __future__ import annotations

from datetime import datetime
import uuid

from sqlmodel import SQLModel, Field


class LegalConsentDB(SQLModel, table=True):
    __tablename__ = "legal_consents"

    id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        primary_key=True,
        index=True,
    )

    device_id: str = Field(
        index=True,
        max_length=80,
        description="Mobil cihaz kimliği (X-Device-Id)",
    )

    document_type: str = Field(
        max_length=40,
        description="Örn: terms, privacy, disclaimer",
    )

    document_version: str | None = Field(
        default=None,
        max_length=20,
        description="Opsiyonel: metin sürümü",
    )

    accepted_at: datetime = Field(
        default_factory=datetime.utcnow,
        description="Onay zamanı (kanıt için)",
    )

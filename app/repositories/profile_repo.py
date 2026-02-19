from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlmodel import Session, select

from app.models.profile_db import UserProfileDB


def get_by_device(session: Session, device_id: str) -> Optional[UserProfileDB]:
    stmt = select(UserProfileDB).where(UserProfileDB.device_id == device_id)
    return session.exec(stmt).first()


def upsert_by_device(session: Session, device_id: str, data: dict) -> UserProfileDB:
    obj = get_by_device(session, device_id)
    now = datetime.utcnow()

    if obj is None:
        obj = UserProfileDB(device_id=device_id, **data)
        obj.created_at = now
        obj.updated_at = now
        session.add(obj)
        session.commit()
        session.refresh(obj)
        return obj

    for k, v in data.items():
        setattr(obj, k, v)
    obj.updated_at = now

    session.add(obj)
    session.commit()
    session.refresh(obj)
    return obj

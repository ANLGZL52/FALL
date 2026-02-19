# app/api/v1/routes_admin.py
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlmodel import Session, select, func

from app.db import get_session
from app.models.coffee_db import CoffeeReadingDB
from app.models.tarot_db import TarotReadingDB
from app.models.payment_db import PaymentDB


router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/db-stats")
def db_stats(session: Session = Depends(get_session)):
    coffee_count = session.exec(select(func.count()).select_from(CoffeeReadingDB)).one()
    tarot_count = session.exec(select(func.count()).select_from(TarotReadingDB)).one()
    payment_count = session.exec(select(func.count()).select_from(PaymentDB)).one()

    return {
        "ok": True,
        "counts": {
            "coffee_readings": int(coffee_count or 0),
            "tarot_readings": int(tarot_count or 0),
            "payments": int(payment_count or 0),
        },
    }

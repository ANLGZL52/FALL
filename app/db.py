from __future__ import annotations

from typing import Generator
from sqlmodel import SQLModel, Session, create_engine
from sqlalchemy import text

from app.core.config import settings

# ✅ MODELLERİ MUTLAKA IMPORT ET (create_all için şart)
from app.models.coffee_db import CoffeeReadingDB
from app.models.hand_db import HandReadingDB
from app.models.tarot_db import TarotReadingDB

engine = create_engine(
    settings.database_url,
    echo=False,
    connect_args={"check_same_thread": False} if settings.database_url.startswith("sqlite") else {},
)


def get_session() -> Generator[Session, None, None]:
    with Session(engine) as session:
        yield session


def init_db() -> None:
    # ✅ hangi db'ye bağlıyız? (çok kritik debug)
    try:
        with engine.connect() as conn:
            db_file = conn.execute(text("PRAGMA database_list;")).fetchall()
        print(f"[DB] database_url = {settings.database_url}")
        print(f"[DB] PRAGMA database_list = {db_file}")
    except Exception as e:
        print(f"[DB] Could not read database_list: {e}")

    # ✅ tabloları oluştur
    SQLModel.metadata.create_all(engine)

    # ✅ sqlite ise mini migration
    ensure_hand_schema()
    ensure_tarot_schema()


# -------------------------
# SQLITE MIGRATION HELPERS
# -------------------------

def _sqlite_has_table(table: str) -> bool:
    if not settings.database_url.startswith("sqlite"):
        return False
    q = text("SELECT name FROM sqlite_master WHERE type='table' AND name=:t;")
    with engine.connect() as conn:
        row = conn.execute(q, {"t": table}).fetchone()
    return row is not None


def _sqlite_has_column(table: str, column: str) -> bool:
    if not settings.database_url.startswith("sqlite"):
        return False
    q = text(f"PRAGMA table_info({table});")
    with engine.connect() as conn:
        rows = conn.execute(q).fetchall()
    cols = {r[1] for r in rows}  # (cid, name, type, notnull, dflt_value, pk)
    return column in cols


# -------------------------
# HAND SCHEMA (SQLITE)
# -------------------------

def ensure_hand_schema() -> None:
    # sadece sqlite için mini migration
    if not settings.database_url.startswith("sqlite"):
        return

    table = "hand_readings"
    if not _sqlite_has_table(table):
        return

    alters: list[str] = []

    # ✅ senin backend kodlarının bekledikleri
    if not _sqlite_has_column(table, "dominant_hand"):
        alters.append("ALTER TABLE hand_readings ADD COLUMN dominant_hand VARCHAR;")
    if not _sqlite_has_column(table, "photo_hand"):
        alters.append("ALTER TABLE hand_readings ADD COLUMN photo_hand VARCHAR;")
    if not _sqlite_has_column(table, "relationship_status"):
        alters.append("ALTER TABLE hand_readings ADD COLUMN relationship_status VARCHAR;")
    if not _sqlite_has_column(table, "big_decision"):
        alters.append("ALTER TABLE hand_readings ADD COLUMN big_decision VARCHAR;")

    # (opsiyonel) bazı eski şemalarda yoksa ekle
    if not _sqlite_has_column(table, "updated_at"):
        alters.append("ALTER TABLE hand_readings ADD COLUMN updated_at DATETIME;")
    if not _sqlite_has_column(table, "created_at"):
        alters.append("ALTER TABLE hand_readings ADD COLUMN created_at DATETIME;")

    if alters:
        with engine.begin() as conn:
            for stmt in alters:
                conn.execute(text(stmt))
        print(f"[DB] hand_readings altered: {len(alters)} changes applied.")
    else:
        print("[DB] hand_readings schema OK.")


# -------------------------
# TAROT SCHEMA (SQLITE)
# -------------------------

def ensure_tarot_schema() -> None:
    # sadece sqlite için mini migration
    if not settings.database_url.startswith("sqlite"):
        return

    table = "tarot_readings"
    if not _sqlite_has_table(table):
        return

    alters: list[str] = []

    # ✅ Tarot için route/schema uyumluluğu
    if not _sqlite_has_column(table, "payment_ref"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN payment_ref VARCHAR;")
    if not _sqlite_has_column(table, "rating"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN rating INTEGER;")
    if not _sqlite_has_column(table, "cards_json"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN cards_json VARCHAR;")
    if not _sqlite_has_column(table, "updated_at"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN updated_at DATETIME;")
    if not _sqlite_has_column(table, "created_at"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN created_at DATETIME;")

    if alters:
        with engine.begin() as conn:
            for stmt in alters:
                conn.execute(text(stmt))
        print(f"[DB] tarot_readings altered: {len(alters)} changes applied.")
    else:
        print("[DB] tarot_readings schema OK.")

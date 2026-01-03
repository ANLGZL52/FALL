# app/db.py
from __future__ import annotations

from typing import Generator
from sqlalchemy import text
from sqlmodel import SQLModel, Session, create_engine

from app.core.config import settings

# ✅ MODELLERİ MUTLAKA IMPORT ET (create_all için şart)
from app.models.coffee_db import CoffeeReadingDB  # noqa: F401
from app.models.hand_db import HandReadingDB      # noqa: F401
from app.models.tarot_db import TarotReadingDB    # noqa: F401
from app.models.numerology_db import NumerologyReadingDB  # noqa: F401
from app.models.birthchart_db import BirthChartReadingDB  # noqa: F401
from app.models.personality_db import PersonalityReadingDB  # noqa: F401
from app.models.synastry_db import SynastryReadingDB  # noqa: F401  ✅ NEW


engine = create_engine(
    settings.database_url,
    echo=False,
    connect_args={"check_same_thread": False} if settings.database_url.startswith("sqlite") else {},
)


def get_session() -> Generator[Session, None, None]:
    with Session(engine) as session:
        yield session


def init_db() -> None:
    # ✅ hangi db'ye bağlıyız? (debug)
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
    ensure_numerology_schema()
    ensure_birthchart_schema()
    ensure_personality_schema()
    ensure_synastry_schema()  # ✅ NEW


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
    if not settings.database_url.startswith("sqlite"):
        return

    table = "hand_readings"
    if not _sqlite_has_table(table):
        return

    alters: list[str] = []

    if not _sqlite_has_column(table, "dominant_hand"):
        alters.append("ALTER TABLE hand_readings ADD COLUMN dominant_hand VARCHAR;")
    if not _sqlite_has_column(table, "photo_hand"):
        alters.append("ALTER TABLE hand_readings ADD COLUMN photo_hand VARCHAR;")
    if not _sqlite_has_column(table, "relationship_status"):
        alters.append("ALTER TABLE hand_readings ADD COLUMN relationship_status VARCHAR;")
    if not _sqlite_has_column(table, "big_decision"):
        alters.append("ALTER TABLE hand_readings ADD COLUMN big_decision VARCHAR;")

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
    if not settings.database_url.startswith("sqlite"):
        return

    table = "tarot_readings"
    if not _sqlite_has_table(table):
        return

    alters: list[str] = []

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


# -------------------------
# NUMEROLOGY SCHEMA (SQLITE)
# -------------------------

def ensure_numerology_schema() -> None:
    if not settings.database_url.startswith("sqlite"):
        return

    table = "numerology_readings"
    if not _sqlite_has_table(table):
        return

    alters: list[str] = []

    if not _sqlite_has_column(table, "payment_ref"):
        alters.append("ALTER TABLE numerology_readings ADD COLUMN payment_ref VARCHAR;")
    if not _sqlite_has_column(table, "rating"):
        alters.append("ALTER TABLE numerology_readings ADD COLUMN rating INTEGER;")
    if not _sqlite_has_column(table, "result_text"):
        alters.append("ALTER TABLE numerology_readings ADD COLUMN result_text VARCHAR;")
    if not _sqlite_has_column(table, "updated_at"):
        alters.append("ALTER TABLE numerology_readings ADD COLUMN updated_at DATETIME;")
    if not _sqlite_has_column(table, "created_at"):
        alters.append("ALTER TABLE numerology_readings ADD COLUMN created_at DATETIME;")

    if alters:
        with engine.begin() as conn:
            for stmt in alters:
                conn.execute(text(stmt))
        print(f"[DB] numerology_readings altered: {len(alters)} changes applied.")
    else:
        print("[DB] numerology_readings schema OK.")


# -------------------------
# BIRTHCHART SCHEMA (SQLITE)
# -------------------------

def ensure_birthchart_schema() -> None:
    if not settings.database_url.startswith("sqlite"):
        return

    table = "birthchart_readings"
    if not _sqlite_has_table(table):
        return

    alters: list[str] = []

    if not _sqlite_has_column(table, "birth_time"):
        alters.append("ALTER TABLE birthchart_readings ADD COLUMN birth_time VARCHAR;")
    if not _sqlite_has_column(table, "birth_city"):
        alters.append("ALTER TABLE birthchart_readings ADD COLUMN birth_city VARCHAR;")
    if not _sqlite_has_column(table, "birth_country"):
        alters.append("ALTER TABLE birthchart_readings ADD COLUMN birth_country VARCHAR;")

    if not _sqlite_has_column(table, "payment_ref"):
        alters.append("ALTER TABLE birthchart_readings ADD COLUMN payment_ref VARCHAR;")
    if not _sqlite_has_column(table, "rating"):
        alters.append("ALTER TABLE birthchart_readings ADD COLUMN rating INTEGER;")
    if not _sqlite_has_column(table, "result_text"):
        alters.append("ALTER TABLE birthchart_readings ADD COLUMN result_text VARCHAR;")
    if not _sqlite_has_column(table, "updated_at"):
        alters.append("ALTER TABLE birthchart_readings ADD COLUMN updated_at DATETIME;")
    if not _sqlite_has_column(table, "created_at"):
        alters.append("ALTER TABLE birthchart_readings ADD COLUMN created_at DATETIME;")

    if alters:
        with engine.begin() as conn:
            for stmt in alters:
                conn.execute(text(stmt))
        print(f"[DB] birthchart_readings altered: {len(alters)} changes applied.")
    else:
        print("[DB] birthchart_readings schema OK.")


# -------------------------
# PERSONALITY SCHEMA (SQLITE)
# -------------------------

def ensure_personality_schema() -> None:
    if not settings.database_url.startswith("sqlite"):
        return

    table = "personality_readings"
    if not _sqlite_has_table(table):
        return

    alters: list[str] = []

    if not _sqlite_has_column(table, "payment_ref"):
        alters.append("ALTER TABLE personality_readings ADD COLUMN payment_ref VARCHAR;")
    if not _sqlite_has_column(table, "rating"):
        alters.append("ALTER TABLE personality_readings ADD COLUMN rating INTEGER;")
    if not _sqlite_has_column(table, "result_text"):
        alters.append("ALTER TABLE personality_readings ADD COLUMN result_text VARCHAR;")
    if not _sqlite_has_column(table, "updated_at"):
        alters.append("ALTER TABLE personality_readings ADD COLUMN updated_at DATETIME;")
    if not _sqlite_has_column(table, "created_at"):
        alters.append("ALTER TABLE personality_readings ADD COLUMN created_at DATETIME;")

    if alters:
        with engine.begin() as conn:
            for stmt in alters:
                conn.execute(text(stmt))
        print(f"[DB] personality_readings altered: {len(alters)} changes applied.")
    else:
        print("[DB] personality_readings schema OK.")


# -------------------------
# ✅ SYNSTRY SCHEMA (SQLITE) ✅ NEW
# -------------------------

def ensure_synastry_schema() -> None:
    if not settings.database_url.startswith("sqlite"):
        return

    table = "synastry_readings"
    if not _sqlite_has_table(table):
        return

    alters: list[str] = []

    required_cols = [
        "reading_id",
        "name_a", "birth_date_a", "birth_time_a", "birth_city_a", "birth_country_a",
        "name_b", "birth_date_b", "birth_time_b", "birth_city_b", "birth_country_b",
        "topic", "question",
        "is_paid", "payment_ref", "status",
        "rating", "result_text",
        "updated_at", "created_at",
    ]

    for col in required_cols:
        if not _sqlite_has_column(table, col):
            if col in {"is_paid"}:
                alters.append(f"ALTER TABLE {table} ADD COLUMN {col} BOOLEAN;")
            elif col in {"rating"}:
                alters.append(f"ALTER TABLE {table} ADD COLUMN {col} INTEGER;")
            elif col in {"updated_at", "created_at"}:
                alters.append(f"ALTER TABLE {table} ADD COLUMN {col} DATETIME;")
            else:
                alters.append(f"ALTER TABLE {table} ADD COLUMN {col} VARCHAR;")

    if alters:
        with engine.begin() as conn:
            for stmt in alters:
                conn.execute(text(stmt))
        print(f"[DB] synastry_readings altered: {len(alters)} changes applied.")
    else:
        print("[DB] synastry_readings schema OK.")

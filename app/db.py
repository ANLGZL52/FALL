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
from app.models.synastry_db import SynastryReadingDB  # noqa: F401


def _normalize_database_url(url: str) -> str:
    """
    Railway Postgres DATABASE_URL genelde:
      postgresql://user:pass@host:5432/db

    SQLAlchemy bu formatta default driver olarak psycopg2 arar.
    Biz projede psycopg (v3) kullandığımız için URL'yi:
      postgresql+psycopg://...

    formatına çeviriyoruz.
    """
    if not url:
        return url

    # postgres:// bazen eski format olarak gelir -> postgresql:// gibi davran
    if url.startswith("postgres://"):
        url = "postgresql://" + url[len("postgres://"):]

    # Eğer zaten driver belirtilmişse dokunma
    if url.startswith("postgresql+"):
        return url

    if url.startswith("postgresql://"):
        return "postgresql+psycopg://" + url[len("postgresql://"):]

    return url


db_url = _normalize_database_url(settings.database_url)

connect_args = {}
if db_url.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(
    db_url,
    echo=False,
    connect_args=connect_args,
)


def get_session() -> Generator[Session, None, None]:
    with Session(engine) as session:
        yield session


def init_db() -> None:
    # ✅ hangi db'ye bağlıyız? (debug)
    try:
        if db_url.startswith("sqlite"):
            with engine.connect() as conn:
                db_file = conn.execute(text("PRAGMA database_list;")).fetchall()
            print(f"[DB] database_url = {db_url}")
            print(f"[DB] PRAGMA database_list = {db_file}")
        else:
            print(f"[DB] database_url = {db_url} (non-sqlite)")
    except Exception as e:
        print(f"[DB] Could not read database info: {e}")

    # ✅ tabloları oluştur
    SQLModel.metadata.create_all(engine)

    # ✅ sqlite ise mini migration
    if db_url.startswith("sqlite"):
        ensure_hand_schema()
        ensure_tarot_schema()
        ensure_numerology_schema()
        ensure_birthchart_schema()
        ensure_personality_schema()
        ensure_synastry_schema()


# -------------------------
# SQLITE MIGRATION HELPERS
# -------------------------

def _sqlite_has_table(table: str) -> bool:
    if not db_url.startswith("sqlite"):
        return False
    q = text("SELECT name FROM sqlite_master WHERE type='table' AND name=:t;")
    with engine.connect() as conn:
        row = conn.execute(q, {"t": table}).fetchone()
    return row is not None


def _sqlite_has_column(table: str, column: str) -> bool:
    if not db_url.startswith("sqlite"):
        return False
    q = text(f"PRAGMA table_info({table});")
    with engine.connect() as conn:
        rows = conn.execute(q).fetchall()
    cols = {r[1] for r in rows}  # (cid, name, type, notnull, dflt_value, pk)
    return column in cols


def _sqlite_add_cols(table: str, alters: list[str]) -> None:
    if not alters:
        print(f"[DB] {table} schema OK.")
        return

    with engine.begin() as conn:
        for stmt in alters:
            conn.execute(text(stmt))
    print(f"[DB] {table} altered: {len(alters)} changes applied.")


# -------------------------
# HAND SCHEMA (SQLITE)
# -------------------------

def ensure_hand_schema() -> None:
    if not db_url.startswith("sqlite"):
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

    _sqlite_add_cols(table, alters)


# -------------------------
# TAROT SCHEMA (SQLITE)
# -------------------------

def ensure_tarot_schema() -> None:
    if not db_url.startswith("sqlite"):
        return

    table = "tarot_readings"
    if not _sqlite_has_table(table):
        return

    alters: list[str] = []

    if not _sqlite_has_column(table, "name"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN name VARCHAR;")
    if not _sqlite_has_column(table, "age"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN age INTEGER;")

    if not _sqlite_has_column(table, "topic"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN topic VARCHAR;")
    if not _sqlite_has_column(table, "question"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN question VARCHAR;")
    if not _sqlite_has_column(table, "spread_type"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN spread_type VARCHAR;")

    if not _sqlite_has_column(table, "cards_json"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN cards_json VARCHAR;")

    if not _sqlite_has_column(table, "is_paid"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN is_paid BOOLEAN;")
    if not _sqlite_has_column(table, "payment_ref"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN payment_ref VARCHAR;")

    if not _sqlite_has_column(table, "status"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN status VARCHAR;")

    if not _sqlite_has_column(table, "result_text"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN result_text VARCHAR;")
    if not _sqlite_has_column(table, "rating"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN rating INTEGER;")

    if not _sqlite_has_column(table, "updated_at"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN updated_at DATETIME;")
    if not _sqlite_has_column(table, "created_at"):
        alters.append("ALTER TABLE tarot_readings ADD COLUMN created_at DATETIME;")

    _sqlite_add_cols(table, alters)


# -------------------------
# NUMEROLOGY SCHEMA (SQLITE)
# -------------------------

def ensure_numerology_schema() -> None:
    if not db_url.startswith("sqlite"):
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

    _sqlite_add_cols(table, alters)


# -------------------------
# BIRTHCHART SCHEMA (SQLITE)
# -------------------------

def ensure_birthchart_schema() -> None:
    if not db_url.startswith("sqlite"):
        return

    table = "birthchart_readings"
    if not _sqlite_has_table(table):
        return

    alters: list[str] = []

    if not _sqlite_has_column(table, "birth_time"):
        alters.append("ALTER TABLE birthchart_readings ADD COLUMN birth_time VARCHAR;")

    _sqlite_add_cols(table, alters)


# -------------------------
# PERSONALITY SCHEMA (SQLITE)
# -------------------------

def ensure_personality_schema() -> None:
    if not db_url.startswith("sqlite"):
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

    _sqlite_add_cols(table, alters)


# -------------------------
# SYNSTRY SCHEMA (SQLITE)
# -------------------------

def ensure_synastry_schema() -> None:
    if not db_url.startswith("sqlite"):
        return

    table = "synastry_readings"
    if not _sqlite_has_table(table):
        return

    alters: list[str] = []

    if not _sqlite_has_column(table, "payment_ref"):
        alters.append("ALTER TABLE synastry_readings ADD COLUMN payment_ref VARCHAR;")
    if not _sqlite_has_column(table, "rating"):
        alters.append("ALTER TABLE synastry_readings ADD COLUMN rating INTEGER;")
    if not _sqlite_has_column(table, "result_text"):
        alters.append("ALTER TABLE synastry_readings ADD COLUMN result_text VARCHAR;")
    if not _sqlite_has_column(table, "updated_at"):
        alters.append("ALTER TABLE synastry_readings ADD COLUMN updated_at DATETIME;")
    if not _sqlite_has_column(table, "created_at"):
        alters.append("ALTER TABLE synastry_readings ADD COLUMN created_at DATETIME;")

    _sqlite_add_cols(table, alters)

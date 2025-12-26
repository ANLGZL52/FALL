# app/db.py
from __future__ import annotations

from typing import Generator
from sqlmodel import SQLModel, Session, create_engine
from sqlalchemy import text

from app.core.config import settings


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

    SQLModel.metadata.create_all(engine)
    ensure_hand_schema()


def _sqlite_has_table(table: str) -> bool:
    q = text("SELECT name FROM sqlite_master WHERE type='table' AND name=:t;")
    with engine.connect() as conn:
        row = conn.execute(q, {"t": table}).fetchone()
    return row is not None


def _sqlite_has_column(table: str, column: str) -> bool:
    q = text(f"PRAGMA table_info({table});")
    with engine.connect() as conn:
        rows = conn.execute(q).fetchall()
    cols = {r[1] for r in rows}  # (cid, name, type, notnull, dflt_value, pk)
    return column in cols


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

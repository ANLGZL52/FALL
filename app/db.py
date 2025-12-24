# app/db.py
from pathlib import Path
from sqlmodel import SQLModel, create_engine, Session
from app.core.config import settings

# db dosyası: <project_root>/storage/fall.db gibi olsun
db_path = (settings.upload_base.parent / "fall.db").resolve()
db_path.parent.mkdir(parents=True, exist_ok=True)

DATABASE_URL = f"sqlite:///{db_path.as_posix()}"

engine = create_engine(
    DATABASE_URL,
    echo=False,                 # True yaparsan SQL loglarını görürsün
    connect_args={"check_same_thread": False},  # FastAPI için gerekli
)

def create_db_and_tables() -> None:
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session

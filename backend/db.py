# backend/db.py
import os
from contextlib import contextmanager
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

def _make_url() -> str:
    url = os.getenv("DATABASE_URL")
    if url:
        return url
    host = os.getenv("DB_HOST", "localhost")
    port = os.getenv("DB_PORT", "5432")
    db   = os.getenv("DB_NAME", "foodscanner")
    user = os.getenv("DB_USER", "foodscanner")
    pwd  = os.getenv("DB_PASS", "dev-password")
    return f"postgresql+psycopg://{user}:{pwd}@{host}:{port}/{db}"

DATABASE_URL = _make_url()

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=1800,
    future=True,
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)

def init_db():
    """Ping DB; log if not ready (the launcher ensures local PG)."""
    if os.getenv("SKIP_DB_INIT") == "1":
        print("[db] init_db skipped by SKIP_DB_INIT=1")
        return
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        print("[db] init_db ok")
    except Exception as e:
        print(f"[db] init_db warning: {e}")
        # Do not raise; uvicorn will keep serving. The run script started PG.

@contextmanager
def session_scope():
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()

def get_session():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def ensure_schema_if_dev():
    """
    Create missing tables in DEV only.
    Triggered by ENV=dev or DEV_MODE=1 (set by run_local.sh).
    Safe to call repeatedly.
    """
    import os as _os
    # Only act in dev contexts
    if _os.getenv("ENV", "dev") != "dev" and _os.getenv("DEV_MODE") != "1":
        return
    try:
        # Prefer SQLAlchemy Declarative Base
        from .models import Base as _Base  # type: ignore
        from .db import engine  # self-module ref is fine at runtime
        _Base.metadata.create_all(bind=engine)
        return
    except Exception:
        pass
    # Fallback to SQLModel, if used
    try:
        from sqlmodel import SQLModel as _SQLModel  # type: ignore
        from .db import engine
        _SQLModel.metadata.create_all(engine)
    except Exception:
        # Last-resort: do nothing silently in case models/engine aren’t ready
        pass

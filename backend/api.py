# backend/api.py
from . import models  # ensures metadata is loaded
from contextlib import asynccontextmanager
from fastapi import FastAPI
import logging
logging.getLogger("passlib").setLevel(logging.ERROR)
logging.getLogger("passlib.handlers.bcrypt").setLevel(logging.ERROR)

from .db import init_db
from .api_auth import router as auth_router
from .api_profiles import router as profiles_router
from .api_metadata import router as meta_router
from .assess import router as assess_router
from .ocr import router as ocr_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # ---- Startup ----
    init_db()
    from .db import ensure_schema_if_dev
    ensure_schema_if_dev()
    yield
    # ---- Shutdown ----
    # add any cleanup here (e.g., close db engines, clients, etc.)


app = FastAPI(
    title="FoodScanner API",
    lifespan=lifespan,
)


# health
@app.get("/health", include_in_schema=False)
def health():
    return {"status": "ok"}


# Routers
app.include_router(assess_router, prefix="")
app.include_router(ocr_router, prefix="")
app.include_router(auth_router)
app.include_router(profiles_router)
app.include_router(meta_router)
from fastapi import FastAPI
from .db import init_db
from .api_auth import router as auth_router
from .api_profiles import router as profiles_router
from .api_metadata import router as meta_router
from .assess import router as assess_router
from .ocr import router as ocr_router
app = FastAPI(title="FoodScanner API")

@app.on_event("startup")
def _startup():
    init_db()
    
    # health
@app.get("/health", include_in_schema=False)
def health():
    return {"status": "ok"}
    
app.include_router(assess_router, prefix="")
app.include_router(ocr_router, prefix="")
app.include_router(auth_router)
app.include_router(profiles_router)
app.include_router(meta_router)
app.include_router(assess_router)
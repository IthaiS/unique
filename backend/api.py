from fastapi import FastAPI
from .assess import router as assess_router
from .ocr import router as ocr_router
app = FastAPI(title="FoodLabel AI Backend")
app.include_router(assess_router, prefix="")
app.include_router(ocr_router, prefix="")

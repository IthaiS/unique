# backend/api_metadata.py
from fastapi import APIRouter
from .assess import load_policy
from .schemas import AllowedAllergensResp

router = APIRouter(prefix="/meta", tags=["meta"])

@router.get("/allowed-allergens", response_model=AllowedAllergensResp)
def allowed_allergens():
    pol = load_policy()
    toks = (pol.get("tokens") or {})
    items = toks.get("major_allergens") or []
    return AllowedAllergensResp(allergens=items)

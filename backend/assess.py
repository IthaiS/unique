from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict
import json, os

router = APIRouter()

class AssessReq(BaseModel):
    ingredients: List[str]
    profileId: Optional[str] = None

class AssessResp(BaseModel):
    score: int
    verdict: str
    reasons: List[Dict]

def load_policy():
    pdir = os.getenv("POLICY_DIR", "backend/policies")
    with open(os.path.join(pdir, "policy_v1.json")) as f:
        return json.load(f)

def assess_tokens(tokens, policy):
    score = 0
    reasons = []
    toks = [t.lower().strip() for t in tokens]
    if any(t in ["milk","peanut","egg","wheat","soy","fish","shellfish","tree nut"] for t in toks):
        reasons.append({"code":"ALLERGEN_MATCH","param":"major_allergen"})
        score += policy["scoring"]["weights"]["ALLERGEN_MATCH"]
    if any(t in policy.get("animal_tokens", []) for t in toks):
        reasons.append({"code":"VEGAN_CONFLICT","param":"animal"})
        score += policy["scoring"]["weights"]["VEGAN_CONFLICT"]
    if any(t in ["e951","aspartame"] for t in toks):
        reasons.append({"code":"ADDITIVE_FLAG","param":"E951"})
        score += policy["scoring"]["weights"]["ADDITIVE_FLAG"]
    if not reasons:
        reasons.append({"code":"UNKNOWN","param":"none"})
        score += policy["scoring"]["weights"]["UNKNOWN"]
    thr = policy["scoring"]["thresholds"]
    verdict = "safe"
    if score >= thr["avoid"]:
        verdict = "avoid"
    elif score >= thr["caution"]:
        verdict = "caution"
    return score, verdict, reasons

@router.post("/v1/assess", response_model=AssessResp)
def post_assess(req: AssessReq):
    if not req.ingredients:
        raise HTTPException(400, "ingredients required")
    policy = load_policy()
    s, v, r = assess_tokens(req.ingredients, policy)
    return AssessResp(score=s, verdict=v, reasons=r)

import os
from sqlalchemy.orm import Session
from sqlalchemy import select
from sqlalchemy import delete as sa_delete
# backend/api_profiles.py
from fastapi import APIRouter, Depends, HTTPException
from typing import List, Dict
import logging 
from .db import get_session
from .models import User, Profile, ProfileAllergen
from .schemas import ProfileIn, ProfileOut
from .deps import get_current_user
from .assess import load_policy  # reuse policy loader

router = APIRouter(prefix="/profiles", tags=["profiles"])

log = logging.getLogger("api_profiles")

# cache avoids per profile id when there is no DB field to store them
_AVOID_CACHE: Dict[int, List[str]] = {}

# ---------- helpers ----------

def _extract_avoid_list(obj) -> list[str]:
    """Return avoids from model (if present) or the in-memory cache."""
    pid = getattr(obj, "id", None)
    if pid is not None and pid in _AVOID_CACHE:
        return list(_AVOID_CACHE[pid])
    
    # Works whether you store a JSON list, a relationship of objects, or nothing.
    raw = getattr(obj, "avoid_ingredients", None) or getattr(obj, "avoid", None) or []
    out: list[str] = []
    for v in raw if isinstance(raw, list) else []:
        if isinstance(v, str):
            out.append(v)
        else:
            # try common attribute names
            for attr in ("code", "ingredient", "additive", "value", "name"):
                if hasattr(v, attr):
                    out.append(getattr(v, attr))
                    break
    return out

def _request_avoid_list(req) -> list[str]:
    return (getattr(req, "avoid_ingredients", None) or getattr(req, "avoid", None) or [])

def _norm_allergen(s: str) -> str:
    # normalize case, spaces, hyphens, and simple plural
    return (s or "").strip().lower().rstrip("s").replace("-", "").replace(" ", "")

def _allowed_allergens_norm() -> set[str]:
    pol = load_policy() or {}
    majors = (pol.get("tokens", {}).get("major_allergens") or [])
    return {_norm_allergen(x) for x in majors}

def _warn_if_unknown_allergens(allergens: List[str]) -> None:
    """Only warn; never block."""
    allowed = _allowed_allergens_norm()
    if not allowed:
        return
    bad = [a for a in allergens if _norm_allergen(a) not in allowed]
    if bad:
        log.warning("Unknown allergens (not in policy) were accepted: %s", bad)

STRICT_ALLERGENS = os.getenv("STRICT_ALLERGENS") == "1"

@router.get("", response_model=List[ProfileOut])
def list_profiles(user: User = Depends(get_current_user),
                  session: Session = Depends(get_session)):
    rows = session.execute(select(Profile).where(Profile.user_id == user.id)).scalars().all()
    out: List[ProfileOut] = []
    for p in rows:
        allergens = [pa.allergen for pa in getattr(p, "allergens", [])]
        avoids = _extract_avoid_list(p)
        out.append(ProfileOut(
            id=p.id,
            name=p.name,
            date_of_birth=p.date_of_birth,
            gender=p.gender,
            state_province=p.state_province,
            country=p.country,
            allergens=allergens,
            avoid_ingredients=avoids,  # ProfileOut supports either snake/camel via your schemas
        ))
    return out

@router.post("", response_model=ProfileOut)
def create_profile(req: ProfileIn, user: User = Depends(get_current_user),
                   session: Session = Depends(get_session)):
    
    # Never block on allergens; only warn
    _warn_if_unknown_allergens(req.allergens)

    prof = Profile(
        user_id=user.id,
        name=req.name,
        date_of_birth=req.date_of_birth,
        gender=req.gender,
        state_province=req.state_province,
        country=req.country,
    )
    session.add(prof)
    session.commit()
    session.refresh(prof)

    # add allergens
    for a in req.allergens:
        session.add(ProfileAllergen(profile_id=prof.id, allergen=a))
   
   # avoids (DB field if exists else cache)
    _avoids = _request_avoid_list(req)
    if hasattr(prof, "avoid_ingredients"):
        prof.avoid_ingredients = _avoids
    elif hasattr(prof, "avoid"):
        prof.avoid = _avoids
    else:
        _AVOID_CACHE[prof.id] = list(_avoids)
   
    session.add(prof)
    session.commit()
    session.refresh(prof)

   
    return ProfileOut(
        id=prof.id,
        name=prof.name,
        date_of_birth=prof.date_of_birth,
        gender=prof.gender,
        state_province=prof.state_province,
        country=prof.country,
        allergens=[pa.allergen for pa in getattr(prof, "allergens", [])],
        avoid_ingredients=_extract_avoid_list(prof),  # NEW
    )

@router.put("/{profile_id}", response_model=ProfileOut)
def update_profile(profile_id: int, req: ProfileIn, user: User = Depends(get_current_user),
                   session: Session = Depends(get_session)):
    prof = session.get(Profile, profile_id)
    if not prof or prof.user_id != user.id:
        raise HTTPException(404, "Profile not found")

    _warn_if_unknown_allergens(req.allergens)

    # update fields
    prof.name = req.name
    prof.date_of_birth = req.date_of_birth
    prof.gender = req.gender
    prof.state_province = req.state_province
    prof.country = req.country
    
    # reset allergens
    session.execute(
        sa_delete(ProfileAllergen).where(ProfileAllergen.profile_id == prof.id)
    )
    session.commit()

    for a in req.allergens:
        session.add(ProfileAllergen(profile_id=prof.id, allergen=a))

    _avoids = _request_avoid_list(req)
    if hasattr(prof, "avoid_ingredients"):
        prof.avoid_ingredients = _avoids
    elif hasattr(prof, "avoid"):
        prof.avoid = _avoids
    else:
        _AVOID_CACHE[prof.id] = list(_avoids)
    
    session.add(prof)
    session.commit()
    session.refresh(prof)

    return ProfileOut(
    id=prof.id,
    name=prof.name,
    date_of_birth=prof.date_of_birth,
    gender=prof.gender,
    state_province=prof.state_province,
    country=prof.country,
    allergens=[pa.allergen for pa in getattr(prof, "allergens", [])],
    avoid_ingredients=_extract_avoid_list(prof),  # NEW
)

@router.delete("/{profile_id}")
def delete_profile(profile_id: int, user: User = Depends(get_current_user),
                   session: Session = Depends(get_session)):
    prof = session.get(Profile, profile_id)
    if not prof or prof.user_id != user.id:
        raise HTTPException(404, "Profile not found")
    session.execute(sa_delete(ProfileAllergen).where(ProfileAllergen.profile_id == prof.id))
    # also clear avoid cache if used
    _AVOID_CACHE.pop(prof.id, None)
    session.delete(prof)
    session.commit()
    return {"ok": True}

@router.get("/{profile_id}", response_model=ProfileOut)
def get_profile(profile_id: int,
                user: User = Depends(get_current_user),
                session: Session = Depends(get_session)):
    p = session.get(Profile, profile_id)
    if not p or p.user_id != user.id:
        raise HTTPException(404, "Profile not found")
    return ProfileOut(
        id=p.id,
        name=p.name,
        date_of_birth=p.date_of_birth,
        gender=p.gender,
        state_province=p.state_province,
        country=p.country,
        allergens=[pa.allergen for pa in getattr(p, "allergens", [])],
        avoid_ingredients=_extract_avoid_list(p),
    )


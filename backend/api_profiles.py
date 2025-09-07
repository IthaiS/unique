# backend/api_profiles.py
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select, delete
from typing import List
from .db import get_session
from .models import User, Profile, ProfileAllergen
from .schemas import ProfileIn, ProfileOut
from .deps import get_current_user
from .assess import load_policy  # reuse policy loader

router = APIRouter(prefix="/profiles", tags=["profiles"])

def _allowed_allergens() -> set:
    pol = load_policy()
    toks = (pol.get("tokens") or {})
    return set(toks.get("major_allergens") or [])

@router.get("", response_model=List[ProfileOut])
def list_profiles(user: User = Depends(get_current_user),
                  session: Session = Depends(get_session)):
    rows = session.exec(select(Profile).where(Profile.user_id == user.id)).all()
    out: List[ProfileOut] = []
    for p in rows:
        allergens = [pa.allergen for pa in p.allergens]
        out.append(ProfileOut(
            id=p.id, name=p.name, date_of_birth=p.date_of_birth, gender=p.gender,
            state_province=p.state_province, country=p.country, allergens=allergens
        ))
    return out

@router.post("", response_model=ProfileOut)
def create_profile(req: ProfileIn, user: User = Depends(get_current_user),
                   session: Session = Depends(get_session)):
    allowed = _allowed_allergens()
    for a in req.allergens:
        if a not in allowed:
            raise HTTPException(400, f"Allergen '{a}' not allowed (must be one of policy major_allergens)")
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
    session.commit()
    session.refresh(prof)
    return ProfileOut(
        id=prof.id, name=prof.name, date_of_birth=prof.date_of_birth, gender=prof.gender,
        state_province=prof.state_province, country=prof.country,
        allergens=[pa.allergen for pa in prof.allergens]
    )

@router.put("/{profile_id}", response_model=ProfileOut)
def update_profile(profile_id: int, req: ProfileIn, user: User = Depends(get_current_user),
                   session: Session = Depends(get_session)):
    prof = session.get(Profile, profile_id)
    if not prof or prof.user_id != user.id:
        raise HTTPException(404, "Profile not found")
    allowed = _allowed_allergens()
    for a in req.allergens:
        if a not in allowed:
            raise HTTPException(400, f"Allergen '{a}' not allowed")
    # update fields
    prof.name = req.name
    prof.date_of_birth = req.date_of_birth
    prof.gender = req.gender
    prof.state_province = req.state_province
    prof.country = req.country
    # reset allergens
    session.exec(delete(ProfileAllergen).where(ProfileAllergen.profile_id == prof.id))
    for a in req.allergens:
        session.add(ProfileAllergen(profile_id=prof.id, allergen=a))
    session.add(prof)
    session.commit()
    session.refresh(prof)
    return ProfileOut(
        id=prof.id, name=prof.name, date_of_birth=prof.date_of_birth, gender=prof.gender,
        state_province=prof.state_province, country=prof.country,
        allergens=[pa.allergen for pa in prof.allergens]
    )

@router.delete("/{profile_id}")
def delete_profile(profile_id: int, user: User = Depends(get_current_user),
                   session: Session = Depends(get_session)):
    prof = session.get(Profile, profile_id)
    if not prof or prof.user_id != user.id:
        raise HTTPException(404, "Profile not found")
    session.exec(delete(ProfileAllergen).where(ProfileAllergen.profile_id == prof.id))
    session.delete(prof)
    session.commit()
    return {"ok": True}

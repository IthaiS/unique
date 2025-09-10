from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session

from .db import get_db
from .auth import get_current_user_id  # use the same dep your /profiles uses
from .models import OwnerAccount

router = APIRouter(prefix="/account", tags=["account"])

class OwnerAccountIn(BaseModel):
    email: EmailStr | None = None
    ownerName: str | None = None
    state: str | None = None
    country: str | None = None

class OwnerAccountOut(OwnerAccountIn):
    id: int
    user_id: int

def _row_to_out(row: OwnerAccount) -> OwnerAccountOut:
    return OwnerAccountOut(
        id=row.id,
        user_id=row.user_id,
        email=row.email,
        ownerName=row.owner_name,
        state=row.state,
        country=row.country,
    )

@router.get("/me", response_model=OwnerAccountOut)
def get_me(user_id: int = Depends(get_current_user_id), db: Session = Depends(get_db)):
    row = db.query(OwnerAccount).filter(OwnerAccount.user_id == user_id).first()
    if not row:
        # create an empty record on first access to keep frontend happy
        row = OwnerAccount(user_id=user_id)
        db.add(row)
        db.commit()
        db.refresh(row)
    return _row_to_out(row)

@router.put("/me", response_model=OwnerAccountOut)
def update_me(
    payload: OwnerAccountIn,
    user_id: int = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    row = db.query(OwnerAccount).filter(OwnerAccount.user_id == user_id).first()
    if not row:
        row = OwnerAccount(user_id=user_id)
        db.add(row)

    row.email = payload.email
    row.owner_name = payload.ownerName
    row.state = payload.state
    row.country = payload.country

    db.commit()
    db.refresh(row)
    return _row_to_out(row)

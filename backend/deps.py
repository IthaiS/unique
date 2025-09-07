# backend/deps.py
from fastapi import Depends, Header, HTTPException
from sqlmodel import Session, select
from .db import get_session
from .auth import parse_token
from .models import User

def get_current_user(
    authorization: str | None = Header(default=None),
    session: Session = Depends(get_session)
) -> User:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(401, "Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    uid = parse_token(token)
    if not uid:
        raise HTTPException(401, "Invalid token")
    user = session.get(User, uid)
    if not user:
        raise HTTPException(401, "User not found")
    return user

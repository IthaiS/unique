from sqlalchemy import select
from sqlalchemy.orm import Session
from fastapi import APIRouter, Depends, HTTPException
from .db import get_session
from .models import User
from .auth import hash_password, verify_password, make_token
from .schemas import RegisterReq, LoginReq, TokenResp, AccountResp, AccountUpdateReq
from .deps import get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/register", response_model=TokenResp)
def register(req: RegisterReq, session: Session = Depends(get_session)):
    existing = session.execute(select(User).where(User.email == req.email)).scalars().first()
    if existing:
        raise HTTPException(409, "Email already registered")
    user = User(
        email=req.email,
        password_hash=hash_password(req.password),
        owner_name=req.owner_name,
        state_province=req.state_province,
        country=req.country,
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    return TokenResp(access_token=make_token(user.id))

@router.post("/login", response_model=TokenResp)
def login(req: LoginReq, session: Session = Depends(get_session)):
    user = session.execute(select(User).where(User.email == req.email)).scalars().first()
    if not user or not verify_password(req.password, user.password_hash):
        raise HTTPException(401, "Invalid credentials")
    return TokenResp(access_token=make_token(user.id))

@router.get("/me", response_model=AccountResp)
def me(user: User = Depends(get_current_user)):
    return AccountResp(
        id=user.id, email=user.email,
        owner_name=user.owner_name,
        state_province=user.state_province,
        country=user.country
    )

@router.put("/me", response_model=AccountResp)
def update_me(req: AccountUpdateReq, user: User = Depends(get_current_user),
              session: Session = Depends(get_session)):
    if req.owner_name is not None:
        user.owner_name = req.owner_name
    if req.state_province is not None:
        user.state_province = req.state_province
    if req.country is not None:
        user.country = req.country
    session.add(user)
    session.commit()
    session.refresh(user)
    return AccountResp(
        id=user.id, email=user.email,
        owner_name=user.owner_name,
        state_province=user.state_province,
        country=user.country
    )

@router.get("/auth/ping")
def auth_ping(db: Session = Depends(get_session)):
    # use db here
    return {"ok": True}
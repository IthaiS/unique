# backend/schemas.py
from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import date

class RegisterReq(BaseModel):
    email: EmailStr
    password: str
    owner_name: Optional[str] = None
    state_province: Optional[str] = None
    country: Optional[str] = None

class LoginReq(BaseModel):
    email: EmailStr
    password: str

class TokenResp(BaseModel):
    access_token: str
    token_type: str = "bearer"

class AccountResp(BaseModel):
    id: int
    email: EmailStr
    owner_name: Optional[str]
    state_province: Optional[str]
    country: Optional[str]

class AccountUpdateReq(BaseModel):
    owner_name: Optional[str] = None
    state_province: Optional[str] = None
    country: Optional[str] = None

class ProfileIn(BaseModel):
    name: str
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    state_province: Optional[str] = None
    country: Optional[str] = None
    allergens: List[str] = []

class ProfileOut(BaseModel):
    id: int
    name: str
    date_of_birth: Optional[date]
    gender: Optional[str]
    state_province: Optional[str]
    country: Optional[str]
    allergens: List[str]

class AllowedAllergensResp(BaseModel):
    allergens: List[str]

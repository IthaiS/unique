# backend/schemas.py
from typing import List, Optional
from datetime import date
from pydantic import BaseModel, Field, EmailStr, ConfigDict 


class RegisterReq(BaseModel):
    email: EmailStr
    password: str
    owner_name: Optional[str] = None
    state_province: Optional[str] = Field(default=None, validation_alias="state")
    country: Optional[str] = None

    model_config = ConfigDict(populate_by_name=True)

class LoginReq(BaseModel):
    email: EmailStr
    password: str

class TokenResp(BaseModel):
    access_token: str
    token_type: str = "bearer"


# -------- Account (/auth/me) --------
class AccountResp(BaseModel):
    id: int
    email: EmailStr
    owner_name: Optional[str] = None
    # respond with "state" while the field name stays state_province
    state_province: Optional[str] = Field(default=None, serialization_alias="state")
    country: Optional[str] = None

    # for ORM objects + alias handling
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

class AccountUpdateReq(BaseModel):
    # Clients may send ownerName/state; we map them to our snake_case fields
    email: Optional[EmailStr] = None  # accepted but ignored by update_me (policy)
    owner_name: Optional[str] = Field(default=None, alias="ownerName")
    state_province: Optional[str] = Field(default=None, alias="state")
    country: Optional[str] = None

    # v2 config: allow populating by field name in addition to aliases
    model_config = ConfigDict(populate_by_name=True)

class ProfileIn(BaseModel):
    name: str
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    # accept either "state_province" or "state"
    state_province: Optional[str] = Field(default=None, validation_alias="state")
    country: Optional[str] = None
    allergens: List[str] = Field(default_factory=list)

     # accept avoid_ingredients in payloads without breaking
    # (you can wire it later if/when you store it)
    avoid_ingredients: Optional[List[str]] = Field(default=None, alias="avoidIngredients")

    # <-- this is what the test sends; we can accept it even if we ignore it
    avoid: List[str] = Field(default_factory=list)
    
    # be permissive with extra fields (e.g., avoid_additives) so tests don’t 422
    model_config = ConfigDict(populate_by_name=True, extra="ignore")

class ProfileOut(BaseModel):
    id: int
    name: str
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    state_province: Optional[str] = None
    country: Optional[str] = None
    allergens: List[str] = Field(default_factory=list)
    avoid_ingredients: List[str] = Field(default_factory=list) 

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

class AllowedAllergensResp(BaseModel):
    allergens: List[str]

class ProfileCreateReq(BaseModel):
    name: str
    # allow either "allergens" or (if ever used) "allergenCodes"
    allergens: List[str] = Field(default_factory=list, validation_alias="allergenCodes")
    # allow either "avoid_additives" or "avoidAdditives"
    avoid_additives: List[str] = Field(default_factory=list, validation_alias="avoidAdditives")
    model_config = ConfigDict(populate_by_name=True)

class ProfileUpdateReq(BaseModel):
    name: Optional[str] = None
    allergens: Optional[List[str]] = Field(default=None, validation_alias="allergenCodes")
    avoid_additives: Optional[List[str]] = Field(default=None, validation_alias="avoidAdditives")
    model_config = ConfigDict(populate_by_name=True)

class ProfileResp(BaseModel):
    id: int
    name: str
    allergens: List[str]
    avoid_additives: List[str] = Field(alias="avoidAdditives")
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

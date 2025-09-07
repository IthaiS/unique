# backend/models.py
from typing import Optional, List
from sqlmodel import SQLModel, Field, Relationship
from datetime import date

class ProfileAllergen(SQLModel, table=True):
    profile_id: int = Field(foreign_key="profile.id", primary_key=True)
    allergen: str = Field(index=True, primary_key=True, max_length=64)

class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(index=True, unique=True, max_length=255)
    password_hash: str
    owner_name: Optional[str] = None
    state_province: Optional[str] = None
    country: Optional[str] = None

    profiles: List["Profile"] = Relationship(back_populates="user")

class Profile(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id", index=True)
    name: str
    date_of_birth: Optional[date] = None
    gender: Optional[str] = Field(default=None, max_length=32)
    state_province: Optional[str] = None
    country: Optional[str] = None

    user: User = Relationship(back_populates="profiles")
    allergens: List[ProfileAllergen] = Relationship(
        sa_relationship_kwargs={"cascade": "all, delete-orphan"},
        back_populates=None,
    )

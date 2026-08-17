from datetime import date
from typing import Optional

from pydantic import BaseModel


class PatientCreate(BaseModel):
    name: str
    phone: str
    email: Optional[str] = None
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    address: Optional[str] = None


class PatientUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    address: Optional[str] = None


class PatientResponse(BaseModel):
    id: int
    name: str
    phone: str
    email: Optional[str] = None
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    address: Optional[str] = None

    class Config:
        from_attributes = True
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict


class DoctorCreate(BaseModel):

    name: str
    phone: str
    email: str
    specialization: str
    qualification: str
    consultation_fee: Decimal


class DoctorUpdate(BaseModel):

    name: str | None = None
    phone: str | None = None
    email: str | None = None
    specialization: str | None = None
    qualification: str | None = None
    consultation_fee: Decimal | None = None


class DoctorResponse(BaseModel):

    model_config = ConfigDict(
        from_attributes=True
    )

    id: int
    name: str
    phone: str
    email: str
    specialization: str
    qualification: str
    consultation_fee: Decimal
    created_at: datetime | None = None
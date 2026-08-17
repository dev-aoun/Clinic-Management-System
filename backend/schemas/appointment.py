from datetime import date, time, datetime

from pydantic import BaseModel, ConfigDict


class AppointmentCreate(BaseModel):

    patient_id: int
    doctor_id: int
    appointment_date: date
    appointment_time: time
    status: str = "scheduled"
    notes: str | None = None


class AppointmentUpdate(BaseModel):

    patient_id: int | None = None
    doctor_id: int | None = None
    appointment_date: date | None = None
    appointment_time: time | None = None
    status: str | None = None
    notes: str | None = None


class AppointmentResponse(BaseModel):

    model_config = ConfigDict(
        from_attributes=True
    )

    id: int
    patient_id: int
    doctor_id: int
    appointment_date: date
    appointment_time: time
    status: str
    notes: str | None = None
    created_at: datetime | None = None
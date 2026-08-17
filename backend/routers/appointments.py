from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import SessionLocal

from models.appointment import Appointment
from models.patient import Patient
from models.doctor import Doctor
from models.user import User

from schemas.appointment import (
    AppointmentCreate,
    AppointmentUpdate,
    AppointmentResponse
)

from utils.dependencies import (
    get_current_user,
    require_role
)


router = APIRouter(
    prefix="/appointments",
    tags=["Appointments"]
)


def get_db():
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()


# --------------------------------
# CREATE APPOINTMENT
# Admin + Staff
# --------------------------------

@router.post(
    "/",
    response_model=AppointmentResponse
)
def create_appointment(
    appointment: AppointmentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_role("admin", "staff")
    )
):

    # Check patient exists
    patient = db.query(Patient).filter(
        Patient.id == appointment.patient_id
    ).first()

    if not patient:
        raise HTTPException(
            status_code=404,
            detail="Patient not found"
        )

    # Check doctor exists
    doctor = db.query(Doctor).filter(
        Doctor.id == appointment.doctor_id
    ).first()

    if not doctor:
        raise HTTPException(
            status_code=404,
            detail="Doctor not found"
        )

    new_appointment = Appointment(
        patient_id=appointment.patient_id,
        doctor_id=appointment.doctor_id,
        appointment_date=appointment.appointment_date,
        appointment_time=appointment.appointment_time,
        status=appointment.status,
        notes=appointment.notes
    )

    db.add(new_appointment)
    db.commit()
    db.refresh(new_appointment)

    return new_appointment


# --------------------------------
# GET ALL APPOINTMENTS
# All logged-in users
# --------------------------------

@router.get(
    "/",
    response_model=list[AppointmentResponse]
)
def get_appointments(
    db: Session = Depends(get_db),
    current_user: User = Depends(
        get_current_user
    )
):

    appointments = db.query(
        Appointment
    ).all()

    return appointments


# --------------------------------
# GET ONE APPOINTMENT
# All logged-in users
# --------------------------------

@router.get(
    "/{appointment_id}",
    response_model=AppointmentResponse
)
def get_appointment(
    appointment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        get_current_user
    )
):

    appointment = db.query(
        Appointment
    ).filter(
        Appointment.id == appointment_id
    ).first()

    if not appointment:
        raise HTTPException(
            status_code=404,
            detail="Appointment not found"
        )

    return appointment


# --------------------------------
# UPDATE APPOINTMENT
# Admin + Doctor + Staff
# --------------------------------

@router.put(
    "/{appointment_id}",
    response_model=AppointmentResponse
)
def update_appointment(
    appointment_id: int,
    appointment_data: AppointmentUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_role("admin", "doctor", "staff")
    )
):

    appointment = db.query(
        Appointment
    ).filter(
        Appointment.id == appointment_id
    ).first()

    if not appointment:
        raise HTTPException(
            status_code=404,
            detail="Appointment not found"
        )

    update_data = appointment_data.model_dump(
        exclude_unset=True
    )

    # If patient is being changed, verify patient
    if "patient_id" in update_data:

        patient = db.query(Patient).filter(
            Patient.id == update_data["patient_id"]
        ).first()

        if not patient:
            raise HTTPException(
                status_code=404,
                detail="Patient not found"
            )

    # If doctor is being changed, verify doctor
    if "doctor_id" in update_data:

        doctor = db.query(Doctor).filter(
            Doctor.id == update_data["doctor_id"]
        ).first()

        if not doctor:
            raise HTTPException(
                status_code=404,
                detail="Doctor not found"
            )

    for key, value in update_data.items():
        setattr(appointment, key, value)

    db.commit()
    db.refresh(appointment)

    return appointment


# --------------------------------
# DELETE APPOINTMENT
# Admin only
# --------------------------------

@router.delete(
    "/{appointment_id}"
)
def delete_appointment(
    appointment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_role("admin")
    )
):

    appointment = db.query(
        Appointment
    ).filter(
        Appointment.id == appointment_id
    ).first()

    if not appointment:
        raise HTTPException(
            status_code=404,
            detail="Appointment not found"
        )

    db.delete(appointment)
    db.commit()

    return {
        "message": "Appointment deleted successfully"
    }
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import SessionLocal

from models.doctor import Doctor
from models.user import User

from schemas.doctor import (
    DoctorCreate,
    DoctorUpdate,
    DoctorResponse
)

from utils.dependencies import (
    get_current_user,
    require_role
)


router = APIRouter(
    prefix="/doctors",
    tags=["Doctors"]
)


def get_db():
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()


# --------------------------------
# CREATE DOCTOR
# Admin only
# --------------------------------

@router.post(
    "/",
    response_model=DoctorResponse
)
def create_doctor(
    doctor: DoctorCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_role("admin")
    )
):

    new_doctor = Doctor(
        name=doctor.name,
        phone=doctor.phone,
        email=doctor.email,
        specialization=doctor.specialization,
        qualification=doctor.qualification,
        consultation_fee=doctor.consultation_fee
    )

    db.add(new_doctor)
    db.commit()
    db.refresh(new_doctor)

    return new_doctor


# --------------------------------
# GET ALL DOCTORS
# All logged-in users
# --------------------------------

@router.get(
    "/",
    response_model=list[DoctorResponse]
)
def get_doctors(
    db: Session = Depends(get_db),
    current_user: User = Depends(
        get_current_user
    )
):

    doctors = db.query(Doctor).all()

    return doctors


# --------------------------------
# GET ONE DOCTOR
# All logged-in users
# --------------------------------

@router.get(
    "/{doctor_id}",
    response_model=DoctorResponse
)
def get_doctor(
    doctor_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        get_current_user
    )
):

    doctor = db.query(Doctor).filter(
        Doctor.id == doctor_id
    ).first()

    if not doctor:
        raise HTTPException(
            status_code=404,
            detail="Doctor not found"
        )

    return doctor


# --------------------------------
# UPDATE DOCTOR
# Admin only
# --------------------------------

@router.put(
    "/{doctor_id}",
    response_model=DoctorResponse
)
def update_doctor(
    doctor_id: int,
    doctor_data: DoctorUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_role("admin")
    )
):

    doctor = db.query(Doctor).filter(
        Doctor.id == doctor_id
    ).first()

    if not doctor:
        raise HTTPException(
            status_code=404,
            detail="Doctor not found"
        )

    update_data = doctor_data.model_dump(
        exclude_unset=True
    )

    for key, value in update_data.items():
        setattr(doctor, key, value)

    db.commit()
    db.refresh(doctor)

    return doctor


# --------------------------------
# DELETE DOCTOR
# Admin only
# --------------------------------

@router.delete(
    "/{doctor_id}"
)
def delete_doctor(
    doctor_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_role("admin")
    )
):

    doctor = db.query(Doctor).filter(
        Doctor.id == doctor_id
    ).first()

    if not doctor:
        raise HTTPException(
            status_code=404,
            detail="Doctor not found"
        )

    db.delete(doctor)
    db.commit()

    return {
        "message": "Doctor deleted successfully"
    }
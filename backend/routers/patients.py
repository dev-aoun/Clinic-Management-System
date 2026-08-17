from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import SessionLocal

from models.patient import Patient
from models.user import User

from schemas.patient import (
    PatientCreate,
    PatientUpdate,
    PatientResponse
)

from utils.dependencies import get_current_user


router = APIRouter(
    prefix="/patients",
    tags=["Patients"]
)


def get_db():
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()


# -------------------------
# CREATE PATIENT
# -------------------------

@router.post(
    "/",
    response_model=PatientResponse
)
def create_patient(
    patient: PatientCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    new_patient = Patient(
        name=patient.name,
        phone=patient.phone,
        email=patient.email,
        date_of_birth=patient.date_of_birth,
        gender=patient.gender,
        address=patient.address
    )

    db.add(new_patient)
    db.commit()
    db.refresh(new_patient)

    return new_patient


# -------------------------
# GET ALL PATIENTS
# -------------------------

@router.get(
    "/",
    response_model=list[PatientResponse]
)
def get_patients(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    patients = db.query(Patient).all()

    return patients


# -------------------------
# GET ONE PATIENT
# -------------------------

@router.get(
    "/{patient_id}",
    response_model=PatientResponse
)
def get_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    patient = db.query(Patient).filter(
        Patient.id == patient_id
    ).first()

    if not patient:
        raise HTTPException(
            status_code=404,
            detail="Patient not found"
        )

    return patient


# -------------------------
# UPDATE PATIENT
# -------------------------

@router.put(
    "/{patient_id}",
    response_model=PatientResponse
)
def update_patient(
    patient_id: int,
    patient_data: PatientUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    patient = db.query(Patient).filter(
        Patient.id == patient_id
    ).first()

    if not patient:
        raise HTTPException(
            status_code=404,
            detail="Patient not found"
        )

    update_data = patient_data.model_dump(
        exclude_unset=True
    )

    for key, value in update_data.items():
        setattr(patient, key, value)

    db.commit()
    db.refresh(patient)

    return patient


# -------------------------
# DELETE PATIENT
# -------------------------

@router.delete(
    "/{patient_id}"
)
def delete_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):

    patient = db.query(Patient).filter(
        Patient.id == patient_id
    ).first()

    if not patient:
        raise HTTPException(
            status_code=404,
            detail="Patient not found"
        )

    db.delete(patient)
    db.commit()

    return {
        "message": "Patient deleted successfully"
    }
from sqlalchemy import Column, Integer, Date, Time, String, Text, TIMESTAMP, ForeignKey
from sqlalchemy.sql import func

from database import Base


class Appointment(Base):
    __tablename__ = "appointments"

    id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    patient_id = Column(
        Integer,
        ForeignKey("patients.id"),
        nullable=False
    )

    doctor_id = Column(
        Integer,
        ForeignKey("doctors.id"),
        nullable=False
    )

    appointment_date = Column(
        Date,
        nullable=False
    )

    appointment_time = Column(
        Time,
        nullable=False
    )

    status = Column(
        String(30),
        nullable=False,
        default="scheduled"
    )

    notes = Column(
        Text,
        nullable=True
    )

    created_at = Column(
        TIMESTAMP,
        server_default=func.current_timestamp()
    )
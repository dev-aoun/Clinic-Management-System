from sqlalchemy import Column, Integer, String, Numeric, TIMESTAMP
from sqlalchemy.sql import func

from database import Base


class Doctor(Base):
    __tablename__ = "doctors"

    id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    name = Column(
        String(100),
        nullable=False
    )

    phone = Column(
        String(30),
        nullable=False
    )

    email = Column(
        String(150),
        nullable=False
    )

    specialization = Column(
        String(100),
        nullable=False
    )

    qualification = Column(
        String(150),
        nullable=False
    )

    consultation_fee = Column(
        Numeric(10, 2),
        nullable=False
    )

    created_at = Column(
        TIMESTAMP,
        server_default=func.current_timestamp()
    )
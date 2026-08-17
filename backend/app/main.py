from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers.auth import router as auth_router
from routers.patients import router as patients_router
from routers.doctors import router as doctors_router
from routers.appointments import router as appointments_router

app = FastAPI(
    title="Clinic Management System API",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(patients_router)
app.include_router(doctors_router)
app.include_router(appointments_router)


@app.get("/")
def root():
    return {
        "message": "Clinic Management System API is running"
    }
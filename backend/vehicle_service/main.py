#vehicle_Service/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from core.db import Base, engine
from core.config import ALLOWED_ORIGINS
from routes.vehicles import router as vehicles_router
from models import vehicles as _models  # ensure model is imported before create_all

app = FastAPI(title="Vehicle Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS if ALLOWED_ORIGINS != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(vehicles_router, prefix="/vehicles", tags=["vehicles"])

@app.get("/vehicles/health")
def health():
    return {"status": "vehicle-service healthy"}

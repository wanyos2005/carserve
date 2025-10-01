#vehicle_Service/main.py
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import logging

from core.db import Base, engine
from core.config import ALLOWED_ORIGINS
from routes.insurance import router as insurance_router
from models import insurance as _models  # ensure model is imported before create_all

app = FastAPI(title="Insurance", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS if ALLOWED_ORIGINS != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
@app.middleware("http")
async def log_requests(request: Request, call_next):
    body = await request.body()
    logging.getLogger("uvicorn").info(
        f"Incoming {request.method} {request.url} | Body: {body.decode() if body else 'EMPTY'}"
    )
    response = await call_next(request)
    return response

app.include_router(insurance_router, prefix="/insurance", tags=["insurance"])

@app.get("/insurance/health")
def health():
    return {"status": "insurance-service healthy"}

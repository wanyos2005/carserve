#insurance_service/main.py
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import logging

from core.db import Base, engine
from core.config import ALLOWED_ORIGINS
from routes.insurance import router as insurance_router
from routes.claims import router as claims_router
from routes.risk_scoring import router as risk_scoring_router
from models import insurance as _models  # ensure model is imported before create_all

app = FastAPI(title="Insurance Service", version="2.0.0", description="Enhanced insurance service with claims, risk scoring, and partner management")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS if ALLOWED_ORIGINS != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    body = await request.body()
    logging.getLogger("uvicorn").info(
        f"Incoming {request.method} {request.url} | Body: {body.decode() if body else 'EMPTY'}"
    )
    response = await call_next(request)
    return response

# Include routers
app.include_router(insurance_router, prefix="/insurance", tags=["insurance-policies"])
app.include_router(claims_router, prefix="/insurance/claims", tags=["insurance-claims"])
app.include_router(risk_scoring_router, prefix="/insurance/risk", tags=["risk-scoring"])

# Health check endpoints
@app.get("/health")
def health_root():
    return {"status": "healthy"}

@app.get("/metrics")
def metrics():
    return {"status": "metrics endpoint", "message": "Prometheus metrics not implemented yet"}

@app.get("/insurance/health")
def health():
    return {
        "status": "insurance-service healthy",
        "version": "2.0.0",
        "features": [
            "Enhanced policy management",
            "Claims processing",
            "Risk scoring engine",
            "Insurance partner management",
            "Quote marketplace"
        ]
    }

# Root endpoint
@app.get("/")
def root():
    return {
        "service": "insurance-service",
        "version": "2.0.0",
        "status": "running",
        "docs": "/docs"
    }

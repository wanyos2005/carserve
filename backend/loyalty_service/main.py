# backend/loyalty_service/main.py
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import logging
import os

from core.db import Base, engine
from core.config import settings
from routers import loyalty as loyalty_router
from models import loyalty as _models  # Ensure models are imported

app = FastAPI(title="Loyalty Service", version="1.0.0")

# CORS
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",") if os.getenv("ALLOWED_ORIGINS") != "*" else ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
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
app.include_router(loyalty_router.router, prefix="/loyalty", tags=["loyalty"])

# Health checks
@app.get("/")
def root():
    return {"service": "loyalty-service", "status": "ok"}

@app.get("/health")
def health():
    return {"status": "healthy"}

@app.get("/metrics")
def metrics():
    return {"status": "metrics endpoint", "message": "Prometheus metrics not implemented yet"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8009"))
    uvicorn.run(app, host="0.0.0.0", port=port)


#backend/service_provider_service/app/main.py
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from app.core.db import Base, engine
from app.core.config import ALLOWED_ORIGINS
from app.routes.providers import router as providers_router
from app.models import provider as _models  # ensure models are imported before create_all
import logging

app = FastAPI(title="Service Provider Service", version="1.0.0")

# Setup CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS if ALLOWED_ORIGINS != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Middleware for logging requests
@app.middleware("http")
async def log_requests(request: Request, call_next):
    body = await request.body()
    logging.getLogger("uvicorn").info(
        f"Incoming {request.method} {request.url} | Body: {body.decode() if body else 'EMPTY'}"
    )
    response = await call_next(request)
    return response

# Register routes
app.include_router(providers_router, prefix="", tags=["service-providers"])

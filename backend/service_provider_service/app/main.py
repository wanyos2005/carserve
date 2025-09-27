#backend/service_provider_service/app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.db import Base, engine
from app.core.config import ALLOWED_ORIGINS
from app.routes.providers import router as providers_router
from app.models import provider as _models  # ensure models are imported before create_all

app = FastAPI(title="Service Provider Service", version="1.0.0")

# Setup CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS if ALLOWED_ORIGINS != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routes
app.include_router(providers_router, prefix="", tags=["service-providers"])


from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
import logging

from core.db import Base, engine
from core.config import ALLOWED_ORIGINS
from routes.vehicles import router as vehicles_router
from models import vehicles as _models  # ensure model is imported before create_all

app = FastAPI(title="Vehicle Service", version="1.0.0")

# --- Logging setup ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("vehicle-service")

# --- CORS ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS if ALLOWED_ORIGINS != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Request logging ---
@app.middleware("http")
async def log_requests(request: Request, call_next):
    body = await request.body()
    logger.info(
        f"Incoming {request.method} {request.url} | Body: {body.decode() if body else 'EMPTY'}"
    )
    response = await call_next(request)
    return response


# --- Global validation error handler ---
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    logger.error(f"Validation error on {request.url}: {exc.errors()}")
    return JSONResponse(
        status_code=422,
        content={"detail": exc.errors()},
    )


# --- Routers ---
app.include_router(vehicles_router, prefix="/vehicles", tags=["vehicles"])

@app.get("/vehicles/health")
def health():
    return {"status": "vehicle-service healthy"}

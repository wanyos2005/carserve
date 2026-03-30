# backend/alert_service/main.py
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import logging

from core.db import Base, engine
from sqlalchemy import text
from core.config import ALLOWED_ORIGINS
from routes.alerts import router as alerts_router
from routes.rules import router as rules_router
from routes.broadcast_alerts import router as broadcast_alerts_router
from routes.incidents import router as incidents_router
# Centralized notifications now integrated into alerts router
from services.metrics import snapshot
from models import alert as _models  # ensure all models imported before create_all

app = FastAPI(
    title="Alert Service",
    version="1.0.0",
    description="Smart mobility companion alert system with insurance, service, and promotional notifications",
    redirect_slashes=False,
)

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
    logging.getLogger("uvicorn").info(
        f"Incoming {request.method} {request.url}"
    )
    response = await call_next(request)
    try:
        logging.getLogger("uvicorn").info(
            f"Responded {request.method} {request.url} | Status: {getattr(response, 'status_code', 'unknown')}"
        )
    except Exception:
        pass
    return response

# Include routers
app.include_router(alerts_router, prefix="/alerts", tags=["alerts"])
app.include_router(rules_router, prefix="/rules", tags=["alert-rules"])
app.include_router(broadcast_alerts_router, prefix="/broadcast-alerts", tags=["drivon-alerts"])
app.include_router(incidents_router, prefix="/incidents", tags=["drivon-alerts"])
# Notifications consolidated under /alerts

# Add direct route for /rules (without trailing slash) to handle nginx forwarding
from routes.rules import get_alert_rules
from core.db import get_db
app.get("/rules")(get_alert_rules)

# Ensure schema and tables exist on startup (useful in dev without running migrations)
@app.on_event("startup")
def ensure_db_objects():
    try:
        with engine.begin() as connection:
            connection.execute(text("CREATE SCHEMA IF NOT EXISTS alerts"))
        Base.metadata.create_all(bind=engine)
        logging.getLogger("uvicorn").info("DB initialized: ensured schema 'alerts' and created tables if missing")
    except Exception as exc:
        logging.getLogger("uvicorn").error(f"DB init failed: {exc}")

# Health check endpoint
@app.get("/health")
def health():
    data = snapshot()
    return {
        "status": "alert-service healthy",
        "version": "1.0.0",
        "features": [
            "Insurance expiry reminders",
            "Service due notifications",
            "Promotional alerts",
            "Multi-channel delivery",
            "Smart alert rules engine",
            "Drivon Alerts: broadcast safety/weather/security/route alerts",
            "Drivon Alerts: user incident reporting",
        ],
        "metrics": data,
    }

# Root endpoint
@app.get("/")
def root():
    return {
        "service": "alert-service",
        "version": "1.0.0",
        "status": "running",
        "docs": "/docs"
    }

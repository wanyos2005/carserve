# backend/booking_service/main.py
from fastapi import FastAPI, Request
from routers import bookings, service_logs
from core.db import engine
from models import booking as booking_models
import sqlalchemy
import logging

app = FastAPI(title="Booking Service")

# --- Request logger middleware ---
@app.middleware("http")
async def log_requests(request: Request, call_next):
    body = await request.body()
    logging.getLogger("uvicorn").info(
        f"Incoming {request.method} {request.url}: {body.decode()}"
    )
    response = await call_next(request)
    return response

# --- Routers ---
# Explicit prefixes are better so your docs stay clean
app.include_router(bookings.router, prefix="/bookings")
app.include_router(service_logs.router, prefix="/service-logs")



# --- Health check ---
@app.get("/")
def root():
    return {"service": "booking_service", "status": "ok"}

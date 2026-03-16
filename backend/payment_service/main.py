from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import logging

from core.db import Base, engine
from core.config import ALLOWED_ORIGINS
from routes.transactions import router as transactions_router
from routes.webhooks import router as webhooks_router
from routes.daraja import router as daraja_router

# Ensure all models are registered before create_all
import models.transaction as _tx_models
import models.webhook as _wh_models

# Create the 'payments' schema and all tables if they don't exist
from sqlalchemy import text
with engine.connect() as conn:
    conn.execute(text("CREATE SCHEMA IF NOT EXISTS payments"))
    conn.commit()

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Payment Service", version="1.0.0")

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

app.include_router(transactions_router, prefix="/mpesa/transactions", tags=["transactions"])
app.include_router(webhooks_router, prefix="/webhooks", tags=["webhooks"])
app.include_router(daraja_router, prefix="/daraja", tags=["daraja"])

@app.get("/health")
def health():
    return {"status": "payment-service healthy"}

@app.get("/metrics")
def metrics():
    return {"status": "metrics endpoint", "message": "Prometheus metrics not implemented yet"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8010)

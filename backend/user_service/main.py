# backend/user_service/main.py and user.py working perfectly for authentication apparently
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import users as users_router
from core.db import Base, engine
from sqlalchemy import text

# In production, schemas and tables are managed via Alembic migrations.
# We avoid implicit table creation here to prevent drift across environments.

app = FastAPI(title="User Service")

# Allow CORS (update allowed origins in prod!)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routes
app.include_router(users_router.router, prefix="", tags=["users"])


@app.get("/")
async def root():
    return {"service": "user-service", "status": "ok"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/metrics")
def metrics():
    return {"status": "metrics endpoint", "message": "Prometheus metrics not implemented yet"}
# backend/user_service/main.py and user.py working perfectly for authentication apparently
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import users as users_router
from core.db import Base, engine

# Create DB tables (use Alembic in prod instead of this)
Base.metadata.create_all(bind=engine)

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
async def health_check():
    return {"status": "users route healthy"}

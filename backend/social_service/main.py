# backend/social_service/main.py
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import logging

from core.db import Base, engine
from core.config import ALLOWED_ORIGINS
from routes.posts import router as posts_router
from routes.stories import router as stories_router
from routes.users import router as users_router
from routes.interactions import router as interactions_router
from routes.search import router as search_router
from routes.analytics import router as analytics_router
from routes.advanced_analytics import router as advanced_analytics_router
from routes.media import router as media_router
from routes.websocket import router as websocket_router
from models import social as _models  # ensure model is imported before create_all

app = FastAPI(
    title="Social Service", 
    version="1.0.0", 
    description="Social hub service for DriveOn platform with posts, stories, interactions, and provider integration"
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
    body = await request.body()
    content_type = request.headers.get("content-type", "")
    if not body:
        body_preview = "EMPTY"
    elif ("application/json" in content_type) or content_type.startswith("text/"):
        try:
            body_preview = body.decode("utf-8")
        except UnicodeDecodeError:
            body_preview = f"<decoding error; {len(body)} bytes>"
    else:
        # Likely multipart/form-data or other binary payload
        body_preview = f"<binary payload; {len(body)} bytes>"

    logging.getLogger("uvicorn").info(
        f"Incoming {request.method} {request.url} | Body: {body_preview}"
    )
    response = await call_next(request)
    return response

# Include routers
app.include_router(posts_router, prefix="/social/posts", tags=["social-posts"])
app.include_router(stories_router, prefix="/social/stories", tags=["social-stories"])
app.include_router(users_router, prefix="/social/users", tags=["social-users"])
app.include_router(interactions_router, prefix="/social/interactions", tags=["social-interactions"])
app.include_router(search_router, prefix="/social/search", tags=["social-search"])
app.include_router(analytics_router, prefix="/social/analytics", tags=["social-analytics"])
app.include_router(advanced_analytics_router, prefix="/social/advanced", tags=["social-advanced-analytics"])
app.include_router(media_router, prefix="/social", tags=["social-media"])
app.include_router(websocket_router, prefix="/social", tags=["social-websocket"])

# Health check endpoints
@app.get("/health")
def health_root():
    return {"status": "healthy"}

@app.get("/metrics")
def metrics():
    return {"status": "metrics endpoint", "message": "Prometheus metrics not implemented yet"}

@app.get("/social/health")
def health():
    return {
        "status": "social-service healthy",
        "version": "1.0.0",
        "features": [
            "Social posts and stories",
            "User interactions (likes, comments, shares)",
            "Content discovery and search",
            "Provider integration and sponsored content",
            "Analytics and insights",
            "Real-time notifications"
        ]
    }

# Root endpoint
@app.get("/")
def root():
    return {
        "service": "social-service",
        "version": "1.0.0",
        "status": "running",
        "docs": "/docs"
    }

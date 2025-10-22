# backend/social_service/routes/advanced_analytics.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from core.db import get_db
from core.security import get_current_user_id
from services.analytics import analytics_service
from schemas.social import SuccessResponse

router = APIRouter()

@router.get("/trending/posts")
def get_trending_posts(
    limit: int = Query(20, ge=1, le=50),
    db: Session = Depends(get_db)
):
    """Get trending posts based on engagement and time decay"""
    try:
        trending_posts = analytics_service.get_trending_posts(limit, db)
        return {
            "trending_posts": trending_posts,
            "count": len(trending_posts),
            "algorithm": "engagement_time_decay"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get trending posts: {str(e)}"
        )

@router.get("/trending/hashtags")
def get_trending_hashtags(
    limit: int = Query(10, ge=1, le=20),
    db: Session = Depends(get_db)
):
    """Get trending hashtags based on recent usage and engagement"""
    try:
        trending_hashtags = analytics_service.get_trending_hashtags(limit, db)
        return {
            "trending_hashtags": trending_hashtags,
            "count": len(trending_hashtags),
            "algorithm": "recent_usage_engagement"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get trending hashtags: {str(e)}"
        )

@router.get("/feed/personalized")
def get_personalized_feed(
    limit: int = Query(20, ge=1, le=50),
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Get personalized feed based on user interests and following"""
    try:
        personalized_posts = analytics_service.get_personalized_feed(user_id, limit, db)
        return {
            "personalized_posts": personalized_posts,
            "count": len(personalized_posts),
            "algorithm": "user_interests_following"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get personalized feed: {str(e)}"
        )

@router.get("/user/{user_id}/analytics")
def get_user_analytics(
    user_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get comprehensive analytics for a user"""
    try:
        # Users can only view their own analytics or public analytics
        if user_id != current_user_id:
            # For now, allow viewing other users' analytics
            # In production, you might want to restrict this
            pass
        
        analytics = analytics_service.get_user_analytics(user_id, db)
        return {
            "user_id": user_id,
            "analytics": analytics,
            "period": "30_days"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get user analytics: {str(e)}"
        )

@router.get("/provider/{provider_id}/analytics")
def get_provider_analytics(
    provider_id: str,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get analytics for service providers"""
    try:
        # Verify user has access to this provider's analytics
        # This would need proper authorization logic
        analytics = analytics_service.get_provider_analytics(provider_id, db)
        return {
            "provider_id": provider_id,
            "analytics": analytics,
            "period": "30_days"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get provider analytics: {str(e)}"
        )

@router.get("/insights/engagement")
def get_engagement_insights(
    days: int = Query(7, ge=1, le=30),
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Get engagement insights for the user's content"""
    try:
        # Get engagement trends over time
        insights = analytics_service.get_engagement_insights(user_id, days, db)
        return {
            "user_id": user_id,
            "insights": insights,
            "period_days": days
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get engagement insights: {str(e)}"
        )

@router.get("/recommendations/users")
def get_user_recommendations(
    limit: int = Query(10, ge=1, le=20),
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Get user recommendations based on interests and connections"""
    try:
        recommendations = analytics_service.get_user_recommendations(user_id, limit, db)
        return {
            "recommendations": recommendations,
            "count": len(recommendations),
            "algorithm": "interest_connection_analysis"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get user recommendations: {str(e)}"
        )

@router.get("/recommendations/content")
def get_content_recommendations(
    limit: int = Query(10, ge=1, le=20),
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Get content recommendations based on user behavior"""
    try:
        recommendations = analytics_service.get_content_recommendations(user_id, limit, db)
        return {
            "recommendations": recommendations,
            "count": len(recommendations),
            "algorithm": "behavior_analysis"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get content recommendations: {str(e)}"
        )

@router.post("/trending/calculate")
def calculate_trending_scores(
    db: Session = Depends(get_db)
):
    """Manually trigger trending score calculation for all posts"""
    try:
        # This would be a background task in production
        result = analytics_service.calculate_all_trending_scores(db)
        return {
            "message": "Trending scores calculated successfully",
            "posts_processed": result.get("posts_processed", 0),
            "hashtags_processed": result.get("hashtags_processed", 0)
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to calculate trending scores: {str(e)}"
        )

@router.get("/dashboard/overview")
def get_dashboard_overview(
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Get comprehensive dashboard overview for analytics"""
    try:
        overview = analytics_service.get_dashboard_overview(user_id, db)
        return {
            "user_id": user_id,
            "overview": overview,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get dashboard overview: {str(e)}"
        )

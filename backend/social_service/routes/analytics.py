# backend/social_service/routes/analytics.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from core.db import get_db
from core.security import get_current_user_id
from models.social import (
    SocialPost, SocialPostAnalytics, SocialUserProfile, 
    SocialLike, SocialComment, SocialShare, SocialFollow
)
from schemas.social import PostAnalytics, UserAnalytics, ProviderAnalytics

router = APIRouter()

@router.get("/posts/{post_id}", response_model=PostAnalytics)
def get_post_analytics(
    post_id: str,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Get analytics for a specific post"""
    # Check if user owns the post
    post = db.query(SocialPost).filter(
        SocialPost.id == post_id,
        SocialPost.user_id == user_id
    ).first()
    
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found or you don't have permission to view analytics"
        )
    
    analytics = db.query(SocialPostAnalytics).filter(
        SocialPostAnalytics.post_id == post_id
    ).first()
    
    if not analytics:
        return PostAnalytics(
            post_id=post_id,
            views=0,
            likes=0,
            comments=0,
            shares=0,
            engagement_rate=0.0,
            reach=0,
            impressions=0
        )
    
    # Calculate engagement rate
    total_engagement = analytics.likes + analytics.comments + analytics.shares
    engagement_rate = (total_engagement / max(analytics.views, 1)) * 100
    
    return PostAnalytics(
        post_id=post_id,
        views=analytics.views,
        likes=analytics.likes,
        comments=analytics.comments,
        shares=analytics.shares,
        engagement_rate=engagement_rate,
        reach=analytics.views,  # For now, reach = views
        impressions=analytics.views  # For now, impressions = views
    )

@router.get("/user/me", response_model=UserAnalytics)
def get_my_analytics(
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Get analytics for current user"""
    # Get user profile
    profile = db.query(SocialUserProfile).filter(
        SocialUserProfile.user_id == user_id
    ).first()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User profile not found"
        )
    
    # Get posts count
    posts_count = db.query(SocialPost).filter(
        SocialPost.user_id == user_id,
        SocialPost.status == "published"
    ).count()
    
    # Get total likes received
    total_likes = db.query(SocialPostAnalytics).join(SocialPost).filter(
        SocialPost.user_id == user_id
    ).with_entities(func.sum(SocialPostAnalytics.likes)).scalar() or 0
    
    # Get total comments received
    total_comments = db.query(SocialPostAnalytics).join(SocialPost).filter(
        SocialPost.user_id == user_id
    ).with_entities(func.sum(SocialPostAnalytics.comments)).scalar() or 0
    
    # Get total shares received
    total_shares = db.query(SocialPostAnalytics).join(SocialPost).filter(
        SocialPost.user_id == user_id
    ).with_entities(func.sum(SocialPostAnalytics.shares)).scalar() or 0
    
    # Calculate engagement rate
    total_engagement = total_likes + total_comments + total_shares
    total_views = db.query(SocialPostAnalytics).join(SocialPost).filter(
        SocialPost.user_id == user_id
    ).with_entities(func.sum(SocialPostAnalytics.views)).scalar() or 0
    
    engagement_rate = (total_engagement / max(total_views, 1)) * 100
    
    # Calculate followers growth (last 30 days)
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    new_followers = db.query(SocialFollow).filter(
        SocialFollow.following_id == user_id,
        SocialFollow.created_at >= thirty_days_ago
    ).count()
    
    return UserAnalytics(
        user_id=user_id,
        posts_count=posts_count,
        total_likes=total_likes,
        total_comments=total_comments,
        total_shares=total_shares,
        followers_growth=new_followers,
        engagement_rate=engagement_rate
    )

@router.get("/provider/{provider_id}", response_model=ProviderAnalytics)
def get_provider_analytics(
    provider_id: str,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Get analytics for a provider"""
    # Check if user is associated with this provider
    profile = db.query(SocialUserProfile).filter(
        SocialUserProfile.user_id == user_id,
        SocialUserProfile.provider_id == provider_id
    ).first()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to view this provider's analytics"
        )
    
    # Get posts count
    posts_count = db.query(SocialPost).filter(
        SocialPost.provider_id == provider_id,
        SocialPost.status == "published"
    ).count()
    
    # Get sponsored posts count
    sponsored_posts_count = db.query(SocialPost).filter(
        SocialPost.provider_id == provider_id,
        SocialPost.is_sponsored == True,
        SocialPost.status == "published"
    ).count()
    
    # Get total reach
    total_reach = db.query(SocialPostAnalytics).join(SocialPost).filter(
        SocialPost.provider_id == provider_id
    ).with_entities(func.sum(SocialPostAnalytics.views)).scalar() or 0
    
    # Get total engagement
    total_engagement = db.query(SocialPostAnalytics).join(SocialPost).filter(
        SocialPost.provider_id == provider_id
    ).with_entities(
        func.sum(SocialPostAnalytics.likes + SocialPostAnalytics.comments + SocialPostAnalytics.shares)
    ).scalar() or 0
    
    # Calculate conversion rate (placeholder - would need actual conversion tracking)
    conversion_rate = 0.0
    
    # Calculate ROI (placeholder - would need actual revenue tracking)
    roi = 0.0
    
    return ProviderAnalytics(
        provider_id=provider_id,
        posts_count=posts_count,
        sponsored_posts_count=sponsored_posts_count,
        total_reach=total_reach,
        total_engagement=total_engagement,
        conversion_rate=conversion_rate,
        roi=roi
    )

@router.get("/trending/posts")
def get_trending_posts_analytics(
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db)
):
    """Get trending posts with analytics"""
    posts = db.query(SocialPost, SocialPostAnalytics).join(
        SocialPostAnalytics, SocialPost.id == SocialPostAnalytics.post_id
    ).filter(
        SocialPost.status == "published"
    ).order_by(
        desc(SocialPostAnalytics.likes + SocialPostAnalytics.comments + SocialPostAnalytics.shares)
    ).limit(limit).all()
    
    trending = []
    for post, analytics in posts:
        trending.append({
            "post_id": post.id,
            "content": post.content[:100] + "..." if len(post.content) > 100 else post.content,
            "user_id": post.user_id,
            "provider_id": post.provider_id,
            "is_sponsored": post.is_sponsored,
            "views": analytics.views,
            "likes": analytics.likes,
            "comments": analytics.comments,
            "shares": analytics.shares,
            "created_at": post.created_at
        })
    
    return {"trending_posts": trending}

@router.get("/hashtags/trending")
def get_trending_hashtags_analytics(
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db)
):
    """Get trending hashtags with analytics"""
    from models.social import SocialHashtag
    
    hashtags = db.query(SocialHashtag).order_by(
        desc(SocialHashtag.posts_count)
    ).limit(limit).all()
    
    trending = []
    for hashtag in hashtags:
        trending.append({
            "name": hashtag.name,
            "posts_count": hashtag.posts_count,
            "last_used": hashtag.last_used,
            "created_at": hashtag.created_at
        })
    
    return {"trending_hashtags": trending}

@router.get("/engagement/overview")
def get_engagement_overview(
    days: int = Query(30, ge=1, le=365),
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Get engagement overview for the last N days"""
    start_date = datetime.utcnow() - timedelta(days=days)
    
    # Get posts created in the last N days
    posts = db.query(SocialPost).filter(
        SocialPost.user_id == user_id,
        SocialPost.created_at >= start_date,
        SocialPost.status == "published"
    ).all()
    
    total_views = 0
    total_likes = 0
    total_comments = 0
    total_shares = 0
    
    for post in posts:
        analytics = db.query(SocialPostAnalytics).filter(
            SocialPostAnalytics.post_id == post.id
        ).first()
        
        if analytics:
            total_views += analytics.views
            total_likes += analytics.likes
            total_comments += analytics.comments
            total_shares += analytics.shares
    
    return {
        "period_days": days,
        "posts_count": len(posts),
        "total_views": total_views,
        "total_likes": total_likes,
        "total_comments": total_comments,
        "total_shares": total_shares,
        "total_engagement": total_likes + total_comments + total_shares,
        "engagement_rate": ((total_likes + total_comments + total_shares) / max(total_views, 1)) * 100
    }

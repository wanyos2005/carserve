# backend/social_service/routes/search.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from core.db import get_db
from core.security import get_current_user_id_optional
from crud import posts as posts_crud
from models.social import SocialUserProfile, SocialHashtag
from schemas.social import (
    SearchQuery, TrendingHashtag, SuggestedUser, UserStats
)

router = APIRouter()

@router.get("/posts")
def search_posts(
    query: str = Query(..., min_length=1, max_length=100),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    user_id: Optional[int] = Depends(get_current_user_id_optional)
):
    """Search for posts by content or hashtags"""
    skip = (page - 1) * limit
    posts = posts_crud.search_posts(db, query, skip, limit)
    
    # Convert to response format with stats
    post_reads = []
    for post in posts:
        stats = posts_crud.get_post_stats(db, post.id, user_id)
        post_dict = {
            "id": post.id,
            "user_id": post.user_id,
            "provider_id": post.provider_id,
            "content": post.content,
            "media_urls": post.media_urls,
            "hashtags": post.hashtags,
            "type": post.type,
            "is_sponsored": post.is_sponsored,
            "sponsored_by": post.sponsored_by,
            "status": post.status,
            "created_at": post.created_at,
            "updated_at": post.updated_at,
            "stats": stats
        }
        post_reads.append(post_dict)
    
    return {
        "posts": post_reads,
        "total": len(post_reads),
        "page": page,
        "limit": limit,
        "has_more": len(posts) == limit
    }

@router.get("/users")
def search_users(
    query: str = Query(..., min_length=1, max_length=100),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user_id: Optional[int] = Depends(get_current_user_id_optional)
):
    """Search for users by username or display name"""
    skip = (page - 1) * limit
    search_term = f"%{query}%"
    
    profiles = db.query(SocialUserProfile).filter(
        SocialUserProfile.username.ilike(search_term) |
        SocialUserProfile.display_name.ilike(search_term)
    ).offset(skip).limit(limit).all()
    
    users = []
    for profile in profiles:
        users.append({
            "id": profile.id,
            "user_id": profile.user_id,
            "username": profile.username,
            "display_name": profile.display_name,
            "profile_image_url": profile.profile_image_url,
            "bio": profile.bio,
            "is_verified": profile.is_verified,
            "is_provider": profile.is_provider,
            "stats": {
                "followers": profile.followers_count,
                "following": profile.following_count,
                "posts": profile.posts_count,
                "likes": 0
            }
        })
    
    return {
        "users": users,
        "total": len(users),
        "page": page,
        "limit": limit,
        "has_more": len(profiles) == limit
    }

@router.get("/hashtags")
def search_hashtags(
    query: str = Query(..., min_length=1, max_length=100),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Search for hashtags"""
    skip = (page - 1) * limit
    search_term = f"%{query}%"
    
    hashtags = db.query(SocialHashtag).filter(
        SocialHashtag.name.ilike(search_term)
    ).order_by(SocialHashtag.posts_count.desc()).offset(skip).limit(limit).all()
    
    hashtag_list = []
    for hashtag in hashtags:
        hashtag_list.append({
            "name": hashtag.name,
            "posts_count": hashtag.posts_count,
            "last_used": hashtag.last_used
        })
    
    return {
        "hashtags": hashtag_list,
        "total": len(hashtag_list),
        "page": page,
        "limit": limit,
        "has_more": len(hashtags) == limit
    }

@router.get("/trending/hashtags", response_model=List[TrendingHashtag])
def get_trending_hashtags(
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db)
):
    """Get trending hashtags"""
    hashtags = db.query(SocialHashtag).order_by(
        SocialHashtag.posts_count.desc()
    ).limit(limit).all()
    
    trending = []
    for hashtag in hashtags:
        trending.append(TrendingHashtag(
            name=hashtag.name,
            posts_count=hashtag.posts_count,
            last_used=hashtag.last_used
        ))
    
    return trending

@router.get("/trending/users", response_model=List[SuggestedUser])
def get_trending_users(
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db),
    current_user_id: Optional[int] = Depends(get_current_user_id_optional)
):
    """Get trending users (most followed)"""
    profiles = db.query(SocialUserProfile).order_by(
        SocialUserProfile.followers_count.desc()
    ).limit(limit).all()
    
    trending_users = []
    for profile in profiles:
        if current_user_id and profile.user_id == current_user_id:
            continue  # Don't include current user
        
        trending_users.append(SuggestedUser(
            id=profile.id,
            user_id=profile.user_id,
            username=profile.username,
            display_name=profile.display_name,
            profile_image_url=profile.profile_image_url,
            bio=profile.bio,
            is_verified=profile.is_verified,
            is_provider=profile.is_provider,
            stats=UserStats(
                followers=profile.followers_count,
                following=profile.following_count,
                posts=profile.posts_count,
                likes=0
            ),
            is_following=False  # Will be calculated based on follow relationships
        ))
    
    return trending_users

@router.get("/global")
def global_search(
    query: str = Query(..., min_length=1, max_length=100),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    user_id: Optional[int] = Depends(get_current_user_id_optional)
):
    """Global search across posts, users, and hashtags"""
    skip = (page - 1) * limit
    
    # Search posts
    posts = posts_crud.search_posts(db, query, 0, limit // 3)
    
    # Search users
    search_term = f"%{query}%"
    users = db.query(SocialUserProfile).filter(
        SocialUserProfile.username.ilike(search_term) |
        SocialUserProfile.display_name.ilike(search_term)
    ).limit(limit // 3).all()
    
    # Search hashtags
    hashtags = db.query(SocialHashtag).filter(
        SocialHashtag.name.ilike(search_term)
    ).limit(limit // 3).all()
    
    return {
        "posts": [
            {
                "id": post.id,
                "content": post.content[:100] + "..." if len(post.content) > 100 else post.content,
                "user_id": post.user_id,
                "created_at": post.created_at
            } for post in posts
        ],
        "users": [
            {
                "id": user.id,
                "user_id": user.user_id,
                "username": user.username,
                "display_name": user.display_name,
                "is_verified": user.is_verified
            } for user in users
        ],
        "hashtags": [
            {
                "name": hashtag.name,
                "posts_count": hashtag.posts_count
            } for hashtag in hashtags
        ]
    }

# backend/social_service/routes/posts.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from core.db import get_db
from core.security import get_current_user_id, get_current_user_id_optional
from crud import posts as posts_crud, interactions as interactions_crud
from schemas.social import (
    PostCreate, PostUpdate, PostRead, PostStats, 
    FeedQuery, FeedResponse, SuccessResponse, ErrorResponse
)

router = APIRouter()

@router.post("/", response_model=PostRead, status_code=status.HTTP_201_CREATED)
def create_post(
    post_data: PostCreate,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Create a new social post"""
    try:
        post = posts_crud.create_post(db, post_data, user_id)
        stats = posts_crud.get_post_stats(db, post.id, user_id)
        
        # Convert to response format
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
        return PostRead(**post_dict)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create post: {str(e)}"
        )

@router.get("/feed", response_model=FeedResponse)
def get_feed_posts(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    category: Optional[str] = Query(None),
    hashtag: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    user_id: Optional[int] = Depends(get_current_user_id_optional)
):
    """Get personalized feed posts"""
    try:
        skip = (page - 1) * limit
        posts = posts_crud.get_feed_posts(db, user_id or 0, skip, limit, category, hashtag)
        
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
            post_reads.append(PostRead(**post_dict))
        
        has_more = len(posts) == limit
        next_page = page + 1 if has_more else None
        
        return FeedResponse(
            posts=post_reads,
            has_more=has_more,
            next_page=next_page
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get feed posts: {str(e)}"
        )

@router.get("/{post_id}", response_model=PostRead)
def get_post(
    post_id: str,
    db: Session = Depends(get_db),
    user_id: Optional[int] = Depends(get_current_user_id_optional)
):
    """Get a specific post by ID"""
    post = posts_crud.get_post(db, post_id)
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    # Increment view count
    posts_crud.increment_post_views(db, post_id)
    
    stats = posts_crud.get_post_stats(db, post_id, user_id)
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
    return PostRead(**post_dict)

@router.put("/{post_id}", response_model=PostRead)
def update_post(
    post_id: str,
    post_data: PostUpdate,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Update a post"""
    post = posts_crud.update_post(db, post_id, post_data, user_id)
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found or you don't have permission to update it"
        )
    
    stats = posts_crud.get_post_stats(db, post_id, user_id)
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
    return PostRead(**post_dict)

@router.delete("/{post_id}", response_model=SuccessResponse)
def delete_post(
    post_id: str,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Delete a post"""
    success = posts_crud.delete_post(db, post_id, user_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found or you don't have permission to delete it"
        )
    
    return SuccessResponse(message="Post deleted successfully")

@router.post("/{post_id}/like", response_model=SuccessResponse)
def toggle_like_post(
    post_id: str,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Like or unlike a post"""
    # Check if post exists
    post = posts_crud.get_post(db, post_id)
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    liked = interactions_crud.toggle_like(db, user_id, post_id=post_id)
    action = "liked" if liked else "unliked"
    
    return SuccessResponse(
        message=f"Post {action} successfully",
        data={"liked": liked}
    )

@router.post("/{post_id}/share", response_model=SuccessResponse)
def share_post(
    post_id: str,
    message: Optional[str] = None,
    shared_to: Optional[str] = None,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Share a post"""
    # Check if post exists
    post = posts_crud.get_post(db, post_id)
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    share = interactions_crud.create_share(db, user_id, post_id, message, shared_to)
    
    return SuccessResponse(
        message="Post shared successfully",
        data={"share_id": share.id}
    )

@router.get("/{post_id}/stats", response_model=PostStats)
def get_post_stats(
    post_id: str,
    db: Session = Depends(get_db),
    user_id: Optional[int] = Depends(get_current_user_id_optional)
):
    """Get post statistics"""
    # Check if post exists
    post = posts_crud.get_post(db, post_id)
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    return posts_crud.get_post_stats(db, post_id, user_id)

@router.get("/trending", response_model=List[PostRead])
def get_trending_posts(
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db),
    user_id: Optional[int] = Depends(get_current_user_id_optional)
):
    """Get trending posts"""
    posts = posts_crud.get_trending_posts(db, limit)
    
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
        post_reads.append(PostRead(**post_dict))
    
    return post_reads

@router.get("/hashtag/{hashtag}", response_model=List[PostRead])
def get_posts_by_hashtag(
    hashtag: str,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    user_id: Optional[int] = Depends(get_current_user_id_optional)
):
    """Get posts by hashtag"""
    skip = (page - 1) * limit
    posts = posts_crud.get_posts_by_hashtag(db, hashtag, skip, limit)
    
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
        post_reads.append(PostRead(**post_dict))
    
    return post_reads

@router.get("/provider/{provider_id}", response_model=List[PostRead])
def get_provider_posts(
    provider_id: str,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    user_id: Optional[int] = Depends(get_current_user_id_optional)
):
    """Get posts by a specific provider"""
    skip = (page - 1) * limit
    posts = posts_crud.get_provider_posts(db, provider_id, skip, limit)
    
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
        post_reads.append(PostRead(**post_dict))
    
    return post_reads

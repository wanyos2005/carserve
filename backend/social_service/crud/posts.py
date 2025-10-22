# backend/social_service/crud/posts.py
from sqlalchemy.orm import Session
from sqlalchemy import desc, and_, or_, func
from typing import List, Optional, Dict, Any
from models.social import SocialPost, SocialPostAnalytics, SocialLike, SocialShare, SocialComment
from schemas.social import PostCreate, PostUpdate, PostStats
import uuid

def create_post(db: Session, post_data: PostCreate, user_id: int) -> SocialPost:
    """Create a new social post"""
    db_post = SocialPost(
        id=str(uuid.uuid4()),
        user_id=user_id,
        provider_id=post_data.provider_id,
        content=post_data.content,
        media_urls=post_data.media_urls,
        hashtags=post_data.hashtags,
        type=post_data.type,
        is_sponsored=post_data.is_sponsored,
        sponsored_by=post_data.sponsored_by,
        status="published"
    )
    db.add(db_post)
    db.commit()
    db.refresh(db_post)
    
    # Create analytics record
    analytics = SocialPostAnalytics(
        id=str(uuid.uuid4()),
        post_id=db_post.id,
        views=0,
        likes=0,
        comments=0,
        shares=0
    )
    db.add(analytics)
    db.commit()
    
    return db_post

def get_post(db: Session, post_id: str) -> Optional[SocialPost]:
    """Get a post by ID"""
    return db.query(SocialPost).filter(
        and_(SocialPost.id == post_id, SocialPost.status != "deleted")
    ).first()

def get_posts(
    db: Session, 
    skip: int = 0, 
    limit: int = 20,
    user_id: Optional[int] = None,
    provider_id: Optional[str] = None,
    category: Optional[str] = None,
    hashtag: Optional[str] = None
) -> List[SocialPost]:
    """Get posts with filtering options"""
    query = db.query(SocialPost).filter(SocialPost.status == "published")
    
    if user_id:
        query = query.filter(SocialPost.user_id == user_id)
    
    if provider_id:
        query = query.filter(SocialPost.provider_id == provider_id)
    
    if hashtag:
        query = query.filter(SocialPost.hashtags.contains([hashtag]))
    
    return query.order_by(desc(SocialPost.created_at)).offset(skip).limit(limit).all()

def get_feed_posts(
    db: Session,
    user_id: int,
    skip: int = 0,
    limit: int = 20,
    category: Optional[str] = None,
    hashtag: Optional[str] = None
) -> List[SocialPost]:
    """Get personalized feed posts for a user"""
    # For now, return all published posts
    # In the future, this could include following-based filtering
    query = db.query(SocialPost).filter(SocialPost.status == "published")
    
    if hashtag:
        query = query.filter(SocialPost.hashtags.contains([hashtag]))
    
    return query.order_by(desc(SocialPost.created_at)).offset(skip).limit(limit).all()

def update_post(db: Session, post_id: str, post_data: PostUpdate, user_id: int) -> Optional[SocialPost]:
    """Update a post"""
    db_post = db.query(SocialPost).filter(
        and_(SocialPost.id == post_id, SocialPost.user_id == user_id)
    ).first()
    
    if not db_post:
        return None
    
    update_data = post_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_post, field, value)
    
    db.commit()
    db.refresh(db_post)
    return db_post

def delete_post(db: Session, post_id: str, user_id: int) -> bool:
    """Soft delete a post"""
    db_post = db.query(SocialPost).filter(
        and_(SocialPost.id == post_id, SocialPost.user_id == user_id)
    ).first()
    
    if not db_post:
        return False
    
    db_post.status = "deleted"
    db.commit()
    return True

def get_post_stats(db: Session, post_id: str, user_id: Optional[int] = None) -> PostStats:
    """Get post statistics including user interaction status"""
    # Get analytics
    analytics = db.query(SocialPostAnalytics).filter(
        SocialPostAnalytics.post_id == post_id
    ).first()
    
    if not analytics:
        return PostStats()
    
    # Check if user has liked the post
    is_liked = False
    if user_id:
        like = db.query(SocialLike).filter(
            and_(SocialLike.post_id == post_id, SocialLike.user_id == user_id)
        ).first()
        is_liked = like is not None
    
    # Check if user has shared the post
    is_shared = False
    if user_id:
        share = db.query(SocialShare).filter(
            and_(SocialShare.post_id == post_id, SocialShare.user_id == user_id)
        ).first()
        is_shared = share is not None
    
    return PostStats(
        likes=analytics.likes,
        comments=analytics.comments,
        shares=analytics.shares,
        views=analytics.views,
        is_liked_by_user=is_liked,
        is_shared_by_user=is_shared
    )

def increment_post_views(db: Session, post_id: str) -> bool:
    """Increment post view count"""
    analytics = db.query(SocialPostAnalytics).filter(
        SocialPostAnalytics.post_id == post_id
    ).first()
    
    if analytics:
        analytics.views += 1
        db.commit()
        return True
    return False

def get_trending_posts(db: Session, limit: int = 10) -> List[SocialPost]:
    """Get trending posts based on engagement"""
    return db.query(SocialPost).join(SocialPostAnalytics).filter(
        SocialPost.status == "published"
    ).order_by(
        desc(SocialPostAnalytics.likes + SocialPostAnalytics.comments + SocialPostAnalytics.shares)
    ).limit(limit).all()

def get_posts_by_hashtag(db: Session, hashtag: str, skip: int = 0, limit: int = 20) -> List[SocialPost]:
    """Get posts by hashtag"""
    return db.query(SocialPost).filter(
        and_(
            SocialPost.status == "published",
            SocialPost.hashtags.contains([hashtag])
        )
    ).order_by(desc(SocialPost.created_at)).offset(skip).limit(limit).all()

def get_sponsored_posts(db: Session, skip: int = 0, limit: int = 20) -> List[SocialPost]:
    """Get sponsored posts"""
    return db.query(SocialPost).filter(
        and_(
            SocialPost.status == "published",
            SocialPost.is_sponsored == True
        )
    ).order_by(desc(SocialPost.created_at)).offset(skip).limit(limit).all()

def get_provider_posts(db: Session, provider_id: str, skip: int = 0, limit: int = 20) -> List[SocialPost]:
    """Get posts by a specific provider"""
    return db.query(SocialPost).filter(
        and_(
            SocialPost.status == "published",
            SocialPost.provider_id == provider_id
        )
    ).order_by(desc(SocialPost.created_at)).offset(skip).limit(limit).all()

def search_posts(db: Session, query: str, skip: int = 0, limit: int = 20) -> List[SocialPost]:
    """Search posts by content"""
    search_term = f"%{query}%"
    return db.query(SocialPost).filter(
        and_(
            SocialPost.status == "published",
            or_(
                SocialPost.content.ilike(search_term),
                SocialPost.hashtags.contains([query])
            )
        )
    ).order_by(desc(SocialPost.created_at)).offset(skip).limit(limit).all()

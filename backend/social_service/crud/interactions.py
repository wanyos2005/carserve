# backend/social_service/crud/interactions.py
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc, func
from typing import List, Optional
from models.social import SocialLike, SocialShare, SocialComment, SocialFollow, SocialPostAnalytics
from schemas.social import CommentCreate, CommentUpdate
import uuid
import asyncio
from services.alert_integration import SocialNotificationService, NotificationChannel

# Like operations
def toggle_like(db: Session, user_id: int, post_id: Optional[str] = None, comment_id: Optional[str] = None) -> bool:
    """Toggle like on a post or comment"""
    if not post_id and not comment_id:
        return False
    
    # Check if like already exists
    existing_like = db.query(SocialLike).filter(
        and_(
            SocialLike.user_id == user_id,
            or_(
                SocialLike.post_id == post_id,
                SocialLike.comment_id == comment_id
            )
        )
    ).first()
    
    if existing_like:
        # Remove like
        db.delete(existing_like)
        # Update analytics
        if post_id:
            analytics = db.query(SocialPostAnalytics).filter(
                SocialPostAnalytics.post_id == post_id
            ).first()
            if analytics:
                analytics.likes = max(0, analytics.likes - 1)
        db.commit()
        return False
    else:
        # Add like
        new_like = SocialLike(
            id=str(uuid.uuid4()),
            user_id=user_id,
            post_id=post_id,
            comment_id=comment_id
        )
        db.add(new_like)
        # Update analytics
        if post_id:
            analytics = db.query(SocialPostAnalytics).filter(
                SocialPostAnalytics.post_id == post_id
            ).first()
            if analytics:
                analytics.likes += 1
        db.commit()
        return True

def get_likes_count(db: Session, post_id: Optional[str] = None, comment_id: Optional[str] = None) -> int:
    """Get likes count for a post or comment"""
    query = db.query(SocialLike)
    if post_id:
        query = query.filter(SocialLike.post_id == post_id)
    elif comment_id:
        query = query.filter(SocialLike.comment_id == comment_id)
    else:
        return 0
    
    return query.count()

def is_liked_by_user(db: Session, user_id: int, post_id: Optional[str] = None, comment_id: Optional[str] = None) -> bool:
    """Check if user has liked a post or comment"""
    like = db.query(SocialLike).filter(
        and_(
            SocialLike.user_id == user_id,
            or_(
                SocialLike.post_id == post_id,
                SocialLike.comment_id == comment_id
            )
        )
    ).first()
    return like is not None

# Share operations
def create_share(db: Session, user_id: int, post_id: str, message: Optional[str] = None, shared_to: Optional[str] = None) -> SocialShare:
    """Create a share record"""
    share = SocialShare(
        id=str(uuid.uuid4()),
        user_id=user_id,
        post_id=post_id,
        message=message,
        shared_to=shared_to
    )
    db.add(share)
    
    # Update analytics
    analytics = db.query(SocialPostAnalytics).filter(
        SocialPostAnalytics.post_id == post_id
    ).first()
    if analytics:
        analytics.shares += 1
    
    db.commit()
    db.refresh(share)
    return share

def get_shares_count(db: Session, post_id: str) -> int:
    """Get shares count for a post"""
    return db.query(SocialShare).filter(SocialShare.post_id == post_id).count()

def is_shared_by_user(db: Session, user_id: int, post_id: str) -> bool:
    """Check if user has shared a post"""
    share = db.query(SocialShare).filter(
        and_(SocialShare.user_id == user_id, SocialShare.post_id == post_id)
    ).first()
    return share is not None

# Comment operations
def create_comment(db: Session, comment_data: CommentCreate, user_id: int, post_id: str) -> SocialComment:
    """Create a new comment"""
    comment = SocialComment(
        id=str(uuid.uuid4()),
        post_id=post_id,
        user_id=user_id,
        content=comment_data.content,
        parent_id=comment_data.parent_id
    )
    db.add(comment)
    
    # Update analytics (create if doesn't exist)
    analytics = db.query(SocialPostAnalytics).filter(
        SocialPostAnalytics.post_id == post_id
    ).first()
    
    if analytics:
        analytics.comments += 1
    else:
        # Create analytics record if it doesn't exist
        analytics = SocialPostAnalytics(
            id=str(uuid.uuid4()),
            post_id=post_id,
            likes=0,
            comments=1,
            shares=0,
            views=0
        )
        db.add(analytics)
    
    db.commit()
    db.refresh(comment)
    
    # Send notification to post owner (if not the same user)
    try:
        # Get post owner ID (you'll need to implement this based on your post model)
        # For now, we'll assume we can get it from the post_id
        # This is a placeholder - you'll need to implement get_post_owner_id
        # post_owner_id = get_post_owner_id(db, post_id)
        # if post_owner_id != user_id:
        #     asyncio.create_task(
        #         SocialNotificationService().send_comment_notification(
        #             post_owner_id=post_owner_id,
        #             commenter_name="User",  # You'll need to get the actual name
        #             post_id=post_id,
        #             comment_content=comment_data.content
        #         )
        #     )
        pass  # Placeholder for now
    except Exception as e:
        # Don't fail the comment creation if notification fails
        print(f"Failed to send comment notification: {str(e)}")
    
    return comment

def get_comments(db: Session, post_id: str, skip: int = 0, limit: int = 20) -> List[SocialComment]:
    """Get comments for a post"""
    return db.query(SocialComment).filter(
        SocialComment.post_id == post_id
    ).order_by(desc(SocialComment.created_at)).offset(skip).limit(limit).all()

def get_comment(db: Session, comment_id: str) -> Optional[SocialComment]:
    """Get a comment by ID"""
    return db.query(SocialComment).filter(SocialComment.id == comment_id).first()

def update_comment(db: Session, comment_id: str, comment_data: CommentUpdate, user_id: int) -> Optional[SocialComment]:
    """Update a comment"""
    comment = db.query(SocialComment).filter(
        and_(SocialComment.id == comment_id, SocialComment.user_id == user_id)
    ).first()
    
    if not comment:
        return None
    
    comment.content = comment_data.content
    db.commit()
    db.refresh(comment)
    return comment

def delete_comment(db: Session, comment_id: str, user_id: int) -> bool:
    """Delete a comment"""
    comment = db.query(SocialComment).filter(
        and_(SocialComment.id == comment_id, SocialComment.user_id == user_id)
    ).first()
    
    if not comment:
        return False
    
    # Update analytics
    analytics = db.query(SocialPostAnalytics).filter(
        SocialPostAnalytics.post_id == comment.post_id
    ).first()
    if analytics:
        analytics.comments = max(0, analytics.comments - 1)
    
    db.delete(comment)
    db.commit()
    return True

def get_comment_replies(db: Session, parent_comment_id: str, skip: int = 0, limit: int = 10) -> List[SocialComment]:
    """Get replies to a comment"""
    return db.query(SocialComment).filter(
        SocialComment.parent_id == parent_comment_id
    ).order_by(desc(SocialComment.created_at)).offset(skip).limit(limit).all()

# Follow operations
def toggle_follow(db: Session, follower_id: int, following_id: int) -> bool:
    """Toggle follow relationship between users"""
    if follower_id == following_id:
        return False  # Can't follow yourself
    
    existing_follow = db.query(SocialFollow).filter(
        and_(
            SocialFollow.follower_id == follower_id,
            SocialFollow.following_id == following_id
        )
    ).first()
    
    if existing_follow:
        # Unfollow
        db.delete(existing_follow)
        db.commit()
        return False
    else:
        # Follow
        follow = SocialFollow(
            id=str(uuid.uuid4()),
            follower_id=follower_id,
            following_id=following_id
        )
        db.add(follow)
        db.commit()
        return True

def is_following(db: Session, follower_id: int, following_id: int) -> bool:
    """Check if user is following another user"""
    follow = db.query(SocialFollow).filter(
        and_(
            SocialFollow.follower_id == follower_id,
            SocialFollow.following_id == following_id
        )
    ).first()
    return follow is not None

def get_followers(db: Session, user_id: int, skip: int = 0, limit: int = 20) -> List[int]:
    """Get followers of a user"""
    follows = db.query(SocialFollow).filter(
        SocialFollow.following_id == user_id
    ).order_by(desc(SocialFollow.created_at)).offset(skip).limit(limit).all()
    
    return [follow.follower_id for follow in follows]

def get_following(db: Session, user_id: int, skip: int = 0, limit: int = 20) -> List[int]:
    """Get users that a user is following"""
    follows = db.query(SocialFollow).filter(
        SocialFollow.follower_id == user_id
    ).order_by(desc(SocialFollow.created_at)).offset(skip).limit(limit).all()
    
    return [follow.following_id for follow in follows]

def get_followers_count(db: Session, user_id: int) -> int:
    """Get followers count for a user"""
    return db.query(SocialFollow).filter(SocialFollow.following_id == user_id).count()

def get_following_count(db: Session, user_id: int) -> int:
    """Get following count for a user"""
    return db.query(SocialFollow).filter(SocialFollow.follower_id == user_id).count()

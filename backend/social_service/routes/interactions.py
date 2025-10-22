# backend/social_service/routes/interactions.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from core.db import get_db
from core.security import get_current_user_id, get_current_user_id_optional
from crud import interactions as interactions_crud
from schemas.social import (
    CommentCreate, CommentUpdate, CommentRead, 
    LikeCreate, ShareCreate, FollowCreate,
    SuccessResponse
)
from services.alert_integration import SocialNotificationService, NotificationChannel

router = APIRouter()

# Initialize Alert Service integration
alert_integration = SocialNotificationService()

# Comment endpoints
@router.post("/comments", response_model=CommentRead, status_code=status.HTTP_201_CREATED)
def create_comment(
    comment_data: CommentCreate,
    post_id: str,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Create a new comment on a post"""
    try:
        comment = interactions_crud.create_comment(db, comment_data, user_id, post_id)
        return CommentRead(
            id=comment.id,
            post_id=comment.post_id,
            user_id=comment.user_id,
            content=comment.content,
            parent_id=comment.parent_id,
            created_at=comment.created_at,
            updated_at=comment.updated_at,
            likes=0,  # Will be calculated separately
            is_liked_by_user=False,
            replies=[]
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create comment: {str(e)}"
        )

@router.get("/comments/{post_id}", response_model=List[CommentRead])
def get_post_comments(
    post_id: str,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    user_id: Optional[int] = Depends(get_current_user_id_optional)
):
    """Get comments for a post"""
    skip = (page - 1) * limit
    comments = interactions_crud.get_comments(db, post_id, skip, limit)
    
    comment_reads = []
    for comment in comments:
        likes_count = interactions_crud.get_likes_count(db, comment_id=comment.id)
        is_liked = interactions_crud.is_liked_by_user(db, user_id or 0, comment_id=comment.id)
        
        comment_reads.append(CommentRead(
            id=comment.id,
            post_id=comment.post_id,
            user_id=comment.user_id,
            content=comment.content,
            parent_id=comment.parent_id,
            created_at=comment.created_at,
            updated_at=comment.updated_at,
            likes=likes_count,
            is_liked_by_user=is_liked,
            replies=[]
        ))
    
    return comment_reads

@router.put("/comments/{comment_id}", response_model=CommentRead)
def update_comment(
    comment_id: str,
    comment_data: CommentUpdate,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Update a comment"""
    comment = interactions_crud.update_comment(db, comment_id, comment_data, user_id)
    if not comment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Comment not found or you don't have permission to update it"
        )
    
    likes_count = interactions_crud.get_likes_count(db, comment_id=comment.id)
    is_liked = interactions_crud.is_liked_by_user(db, user_id, comment_id=comment.id)
    
    return CommentRead(
        id=comment.id,
        post_id=comment.post_id,
        user_id=comment.user_id,
        content=comment.content,
        parent_id=comment.parent_id,
        created_at=comment.created_at,
        updated_at=comment.updated_at,
        likes=likes_count,
        is_liked_by_user=is_liked,
        replies=[]
    )

@router.delete("/comments/{comment_id}", response_model=SuccessResponse)
def delete_comment(
    comment_id: str,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Delete a comment"""
    success = interactions_crud.delete_comment(db, comment_id, user_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Comment not found or you don't have permission to delete it"
        )
    
    return SuccessResponse(message="Comment deleted successfully")

# Like endpoints
@router.post("/likes", response_model=SuccessResponse)
def toggle_like(
    like_data: LikeCreate,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Like or unlike a post or comment"""
    if not like_data.post_id and not like_data.comment_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Either post_id or comment_id must be provided"
        )
    
    liked = interactions_crud.toggle_like(
        db, user_id, 
        post_id=like_data.post_id, 
        comment_id=like_data.comment_id
    )
    
    action = "liked" if liked else "unliked"
    target = "post" if like_data.post_id else "comment"
    
    return SuccessResponse(
        message=f"{target.capitalize()} {action} successfully",
        data={"liked": liked}
    )

# Share endpoints
@router.post("/shares", response_model=SuccessResponse)
def share_content(
    share_data: ShareCreate,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Share a post"""
    share = interactions_crud.create_share(
        db, user_id, share_data.post_id, 
        share_data.message, share_data.shared_to
    )
    
    return SuccessResponse(
        message="Content shared successfully",
        data={"share_id": share.id}
    )

# Follow endpoints
@router.post("/follows", response_model=SuccessResponse)
def toggle_follow(
    follow_data: FollowCreate,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Follow or unfollow a user"""
    if user_id == follow_data.following_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot follow yourself"
        )
    
    followed = interactions_crud.toggle_follow(db, user_id, follow_data.following_id)
    action = "followed" if followed else "unfollowed"
    
    return SuccessResponse(
        message=f"User {action} successfully",
        data={"following": followed}
    )

@router.get("/follows/{user_id}/followers", response_model=List[int])
def get_user_followers(
    user_id: int,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Get followers of a user"""
    skip = (page - 1) * limit
    return interactions_crud.get_followers(db, user_id, skip, limit)

@router.get("/follows/{user_id}/following", response_model=List[int])
def get_user_following(
    user_id: int,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Get users that a user is following"""
    skip = (page - 1) * limit
    return interactions_crud.get_following(db, user_id, skip, limit)

@router.get("/follows/{user_id}/count")
def get_follow_counts(
    user_id: int,
    db: Session = Depends(get_db)
):
    """Get follow counts for a user"""
    followers_count = interactions_crud.get_followers_count(db, user_id)
    following_count = interactions_crud.get_following_count(db, user_id)
    
    return {
        "followers": followers_count,
        "following": following_count
    }

@router.get("/follows/{follower_id}/{following_id}/status")
def get_follow_status(
    follower_id: int,
    following_id: int,
    db: Session = Depends(get_db)
):
    """Check if one user is following another"""
    is_following = interactions_crud.is_following(db, follower_id, following_id)
    return {"is_following": is_following}

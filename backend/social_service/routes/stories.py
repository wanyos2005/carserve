# backend/social_service/routes/stories.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta
from core.db import get_db
from core.security import get_current_user_id, get_current_user_id_optional
from models.social import SocialStory, SocialStoryView
from schemas.social import StoryCreate, StoryRead, SuccessResponse
import uuid

router = APIRouter()

@router.post("/", response_model=StoryRead, status_code=status.HTTP_201_CREATED)
def create_story(
    story_data: StoryCreate,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Create a new story"""
    try:
        # Stories expire after 24 hours
        expires_at = datetime.utcnow() + timedelta(hours=24)
        
        story = SocialStory(
            id=str(uuid.uuid4()),
            user_id=user_id,
            provider_id=story_data.provider_id,
            content=story_data.content,
            media_url=story_data.media_url,
            type=story_data.type,
            expires_at=expires_at
        )
        db.add(story)
        db.commit()
        db.refresh(story)
        
        return StoryRead(
            id=story.id,
            user_id=story.user_id,
            provider_id=story.provider_id,
            content=story.content,
            media_url=story.media_url,
            type=story.type,
            created_at=story.created_at,
            expires_at=story.expires_at,
            is_viewed=False,
            views_count=0
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create story: {str(e)}"
        )

@router.get("/", response_model=List[StoryRead])
def get_stories(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    user_id: Optional[int] = Depends(get_current_user_id_optional)
):
    """Get active stories"""
    try:
        skip = (page - 1) * limit
        current_time = datetime.utcnow()
        
        stories = db.query(SocialStory).filter(
            SocialStory.expires_at > current_time
        ).order_by(SocialStory.created_at.desc()).offset(skip).limit(limit).all()
        
        story_reads = []
        for story in stories:
            # Check if user has viewed this story
            is_viewed = False
            if user_id:
                view = db.query(SocialStoryView).filter(
                    SocialStoryView.story_id == story.id,
                    SocialStoryView.user_id == user_id
                ).first()
                is_viewed = view is not None
            
            # Get views count
            views_count = db.query(SocialStoryView).filter(
                SocialStoryView.story_id == story.id
            ).count()
            
            story_reads.append(StoryRead(
                id=story.id,
                user_id=story.user_id,
                provider_id=story.provider_id,
                content=story.content,
                media_url=story.media_url,
                type=story.type,
                created_at=story.created_at,
                expires_at=story.expires_at,
                is_viewed=is_viewed,
                views_count=views_count
            ))
        
        return story_reads
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get stories: {str(e)}"
        )

@router.get("/{story_id}", response_model=StoryRead)
def get_story(
    story_id: str,
    db: Session = Depends(get_db),
    user_id: Optional[int] = Depends(get_current_user_id_optional)
):
    """Get a specific story by ID"""
    story = db.query(SocialStory).filter(SocialStory.id == story_id).first()
    if not story:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Story not found"
        )
    
    # Check if story has expired
    if story.expires_at <= datetime.utcnow():
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail="Story has expired"
        )
    
    # Check if user has viewed this story
    is_viewed = False
    if user_id:
        view = db.query(SocialStoryView).filter(
            SocialStoryView.story_id == story.id,
            SocialStoryView.user_id == user_id
        ).first()
        is_viewed = view is not None
    
    # Get views count
    views_count = db.query(SocialStoryView).filter(
        SocialStoryView.story_id == story.id
    ).count()
    
    return StoryRead(
        id=story.id,
        user_id=story.user_id,
        provider_id=story.provider_id,
        content=story.content,
        media_url=story.media_url,
        type=story.type,
        created_at=story.created_at,
        expires_at=story.expires_at,
        is_viewed=is_viewed,
        views_count=views_count
    )

@router.post("/{story_id}/view", response_model=SuccessResponse)
def view_story(
    story_id: str,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Mark a story as viewed by the user"""
    story = db.query(SocialStory).filter(SocialStory.id == story_id).first()
    if not story:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Story not found"
        )
    
    # Check if story has expired
    if story.expires_at <= datetime.utcnow():
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail="Story has expired"
        )
    
    # Check if user has already viewed this story
    existing_view = db.query(SocialStoryView).filter(
        SocialStoryView.story_id == story_id,
        SocialStoryView.user_id == user_id
    ).first()
    
    if not existing_view:
        view = SocialStoryView(
            id=str(uuid.uuid4()),
            story_id=story_id,
            user_id=user_id
        )
        db.add(view)
        db.commit()
    
    return SuccessResponse(message="Story viewed successfully")

@router.delete("/{story_id}", response_model=SuccessResponse)
def delete_story(
    story_id: str,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Delete a story"""
    story = db.query(SocialStory).filter(
        SocialStory.id == story_id,
        SocialStory.user_id == user_id
    ).first()
    
    if not story:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Story not found or you don't have permission to delete it"
        )
    
    db.delete(story)
    db.commit()
    
    return SuccessResponse(message="Story deleted successfully")

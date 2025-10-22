# backend/social_service/routes/users.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from core.db import get_db
from core.security import get_current_user_id, get_current_user_id_optional
from models.social import SocialUserProfile
from schemas.social import (
    UserProfileCreate, UserProfileUpdate, UserProfileRead, 
    UserStats, SuggestedUser, SuccessResponse
)
import uuid

router = APIRouter()

@router.post("/profile", response_model=UserProfileRead, status_code=status.HTTP_201_CREATED)
def create_user_profile(
    profile_data: UserProfileCreate,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Create a user profile"""
    try:
        # Check if profile already exists
        existing_profile = db.query(SocialUserProfile).filter(
            SocialUserProfile.user_id == user_id
        ).first()
        
        if existing_profile:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Profile already exists for this user"
            )
        
        # Check if username is already taken
        existing_username = db.query(SocialUserProfile).filter(
            SocialUserProfile.username == profile_data.username
        ).first()
        
        if existing_username:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already taken"
            )
        
        profile = SocialUserProfile(
            id=str(uuid.uuid4()),
            user_id=user_id,
            username=profile_data.username,
            display_name=profile_data.display_name,
            bio=profile_data.bio,
            profile_image_url=profile_data.profile_image_url,
            is_private=profile_data.is_private,
            allow_messages=profile_data.allow_messages,
            provider_id=profile_data.provider_id
        )
        db.add(profile)
        db.commit()
        db.refresh(profile)
        
        return UserProfileRead(
            id=profile.id,
            user_id=profile.user_id,
            username=profile.username,
            display_name=profile.display_name,
            bio=profile.bio,
            profile_image_url=profile.profile_image_url,
            is_private=profile.is_private,
            allow_messages=profile.allow_messages,
            is_verified=profile.is_verified,
            is_provider=profile.is_provider,
            provider_id=profile.provider_id,
            stats=UserStats(
                followers=profile.followers_count,
                following=profile.following_count,
                posts=profile.posts_count,
                likes=0  # Will be calculated separately
            ),
            created_at=profile.created_at,
            updated_at=profile.updated_at
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create profile: {str(e)}"
        )

@router.get("/profile/me", response_model=UserProfileRead)
def get_my_profile(
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Get current user's profile"""
    profile = db.query(SocialUserProfile).filter(
        SocialUserProfile.user_id == user_id
    ).first()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found"
        )
    
    return UserProfileRead(
        id=profile.id,
        user_id=profile.user_id,
        username=profile.username,
        display_name=profile.display_name,
        bio=profile.bio,
        profile_image_url=profile.profile_image_url,
        is_private=profile.is_private,
        allow_messages=profile.allow_messages,
        is_verified=profile.is_verified,
        is_provider=profile.is_provider,
        provider_id=profile.provider_id,
        stats=UserStats(
            followers=profile.followers_count,
            following=profile.following_count,
            posts=profile.posts_count,
            likes=0  # Will be calculated separately
        ),
        created_at=profile.created_at,
        updated_at=profile.updated_at
    )

@router.get("/profile/{user_id}", response_model=UserProfileRead)
def get_user_profile(
    user_id: int,
    db: Session = Depends(get_db),
    current_user_id: Optional[int] = Depends(get_current_user_id_optional)
):
    """Get a user's profile by user ID"""
    profile = db.query(SocialUserProfile).filter(
        SocialUserProfile.user_id == user_id
    ).first()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found"
        )
    
    return UserProfileRead(
        id=profile.id,
        user_id=profile.user_id,
        username=profile.username,
        display_name=profile.display_name,
        bio=profile.bio,
        profile_image_url=profile.profile_image_url,
        is_private=profile.is_private,
        allow_messages=profile.allow_messages,
        is_verified=profile.is_verified,
        is_provider=profile.is_provider,
        provider_id=profile.provider_id,
        stats=UserStats(
            followers=profile.followers_count,
            following=profile.following_count,
            posts=profile.posts_count,
            likes=0  # Will be calculated separately
        ),
        created_at=profile.created_at,
        updated_at=profile.updated_at
    )

@router.put("/profile", response_model=UserProfileRead)
def update_user_profile(
    profile_data: UserProfileUpdate,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """Update current user's profile"""
    profile = db.query(SocialUserProfile).filter(
        SocialUserProfile.user_id == user_id
    ).first()
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found"
        )
    
    # Check if username is being changed and if it's available
    if profile_data.username and profile_data.username != profile.username:
        existing_username = db.query(SocialUserProfile).filter(
            SocialUserProfile.username == profile_data.username
        ).first()
        
        if existing_username:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already taken"
            )
    
    # Update profile fields
    update_data = profile_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(profile, field, value)
    
    db.commit()
    db.refresh(profile)
    
    return UserProfileRead(
        id=profile.id,
        user_id=profile.user_id,
        username=profile.username,
        display_name=profile.display_name,
        bio=profile.bio,
        profile_image_url=profile.profile_image_url,
        is_private=profile.is_private,
        allow_messages=profile.allow_messages,
        is_verified=profile.is_verified,
        is_provider=profile.is_provider,
        provider_id=profile.provider_id,
        stats=UserStats(
            followers=profile.followers_count,
            following=profile.following_count,
            posts=profile.posts_count,
            likes=0  # Will be calculated separately
        ),
        created_at=profile.created_at,
        updated_at=profile.updated_at
    )

@router.get("/search", response_model=List[SuggestedUser])
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
    
    suggested_users = []
    for profile in profiles:
        # Check if current user is following this user
        is_following = False
        if current_user_id:
            # This would need to be implemented with the follow relationship
            # For now, we'll set it to False
            pass
        
        suggested_users.append(SuggestedUser(
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
            is_following=is_following
        ))
    
    return suggested_users

@router.get("/suggested", response_model=List[SuggestedUser])
def get_suggested_users(
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db),
    current_user_id: Optional[int] = Depends(get_current_user_id_optional)
):
    """Get suggested users to follow"""
    # For now, return verified users and providers
    # In the future, this could be based on mutual connections, interests, etc.
    profiles = db.query(SocialUserProfile).filter(
        SocialUserProfile.is_verified == True
    ).limit(limit).all()
    
    suggested_users = []
    for profile in profiles:
        if current_user_id and profile.user_id == current_user_id:
            continue  # Don't suggest the current user
        
        suggested_users.append(SuggestedUser(
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
    
    return suggested_users

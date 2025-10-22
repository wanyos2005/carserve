# backend/social_service/schemas/social.py
from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum

# Enums
class PostType(str, Enum):
    text = "text"
    image = "image"
    video = "video"
    carousel = "carousel"
    poll = "poll"
    story = "story"

class PostStatus(str, Enum):
    draft = "draft"
    published = "published"
    archived = "archived"
    deleted = "deleted"

class StoryType(str, Enum):
    image = "image"
    video = "video"
    text = "text"

class NotificationType(str, Enum):
    like = "like"
    comment = "comment"
    follow = "follow"
    mention = "mention"
    share = "share"
    story_view = "story_view"

# Base schemas
class PostStats(BaseModel):
    likes: int = 0
    comments: int = 0
    shares: int = 0
    views: int = 0
    is_liked_by_user: bool = False
    is_shared_by_user: bool = False

class UserStats(BaseModel):
    followers: int = 0
    following: int = 0
    posts: int = 0
    likes: int = 0

# Post schemas
class PostBase(BaseModel):
    content: str = Field(..., min_length=1, max_length=2000)
    media_urls: List[str] = Field(default_factory=list)
    hashtags: List[str] = Field(default_factory=list)
    type: PostType = PostType.text
    is_sponsored: bool = False
    sponsored_by: Optional[str] = None

class PostCreate(PostBase):
    provider_id: Optional[str] = None

class PostUpdate(BaseModel):
    content: Optional[str] = Field(None, min_length=1, max_length=2000)
    media_urls: Optional[List[str]] = None
    hashtags: Optional[List[str]] = None
    status: Optional[PostStatus] = None

class PostRead(PostBase):
    id: str
    user_id: int
    provider_id: Optional[str]
    status: PostStatus
    created_at: datetime
    updated_at: datetime
    stats: PostStats
    
    class Config:
        from_attributes = True

# Story schemas
class StoryBase(BaseModel):
    content: Optional[str] = Field(None, max_length=1000)
    media_url: Optional[str] = None
    type: StoryType = StoryType.image

class StoryCreate(StoryBase):
    provider_id: Optional[str] = None

class StoryRead(StoryBase):
    id: str
    user_id: int
    provider_id: Optional[str]
    created_at: datetime
    expires_at: datetime
    is_viewed: bool = False
    views_count: int = 0
    
    class Config:
        from_attributes = True

# Comment schemas
class CommentBase(BaseModel):
    content: str = Field(..., min_length=1, max_length=1000)

class CommentCreate(CommentBase):
    parent_id: Optional[str] = None

class CommentUpdate(BaseModel):
    content: str = Field(..., min_length=1, max_length=1000)

class CommentRead(CommentBase):
    id: str
    post_id: str
    user_id: int
    parent_id: Optional[str]
    created_at: datetime
    updated_at: datetime
    likes: int = 0
    is_liked_by_user: bool = False
    replies: List['CommentRead'] = []
    
    class Config:
        from_attributes = True

# User profile schemas
class UserProfileBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    display_name: Optional[str] = Field(None, max_length=100)
    bio: Optional[str] = Field(None, max_length=500)
    profile_image_url: Optional[str] = None
    is_private: bool = False
    allow_messages: bool = True

class UserProfileCreate(UserProfileBase):
    provider_id: Optional[str] = None

class UserProfileUpdate(BaseModel):
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    display_name: Optional[str] = Field(None, max_length=100)
    bio: Optional[str] = Field(None, max_length=500)
    profile_image_url: Optional[str] = None
    is_private: Optional[bool] = None
    allow_messages: Optional[bool] = None

class UserProfileRead(UserProfileBase):
    id: str
    user_id: int
    is_verified: bool
    is_provider: bool
    provider_id: Optional[str]
    stats: UserStats
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# Interaction schemas
class LikeCreate(BaseModel):
    post_id: Optional[str] = None
    comment_id: Optional[str] = None

class ShareCreate(BaseModel):
    post_id: str
    message: Optional[str] = Field(None, max_length=500)
    shared_to: Optional[str] = None

class FollowCreate(BaseModel):
    following_id: int

# Search and discovery schemas
class SearchQuery(BaseModel):
    query: str = Field(..., min_length=1, max_length=100)
    page: int = Field(1, ge=1)
    limit: int = Field(20, ge=1, le=100)
    type: Optional[str] = None  # posts, users, hashtags

class TrendingHashtag(BaseModel):
    name: str
    posts_count: int
    last_used: datetime

class SuggestedUser(BaseModel):
    id: str
    user_id: int
    username: str
    display_name: Optional[str]
    profile_image_url: Optional[str]
    bio: Optional[str]
    is_verified: bool
    is_provider: bool
    stats: UserStats
    is_following: bool = False

# Feed schemas
class FeedQuery(BaseModel):
    page: int = Field(1, ge=1)
    limit: int = Field(20, ge=1, le=100)
    category: Optional[str] = None
    hashtag: Optional[str] = None
    user_id: Optional[int] = None

class FeedResponse(BaseModel):
    posts: List[PostRead]
    has_more: bool
    next_page: Optional[int] = None

# Analytics schemas
class PostAnalytics(BaseModel):
    post_id: str
    views: int
    likes: int
    comments: int
    shares: int
    engagement_rate: float
    reach: int
    impressions: int

class UserAnalytics(BaseModel):
    user_id: int
    posts_count: int
    total_likes: int
    total_comments: int
    total_shares: int
    followers_growth: int
    engagement_rate: float

class ProviderAnalytics(BaseModel):
    provider_id: str
    posts_count: int
    sponsored_posts_count: int
    total_reach: int
    total_engagement: int
    conversion_rate: float
    roi: float

# Notification schemas
class NotificationBase(BaseModel):
    type: NotificationType
    title: str = Field(..., max_length=200)
    message: str = Field(..., max_length=500)
    related_user_id: Optional[int] = None
    related_post_id: Optional[str] = None
    related_comment_id: Optional[str] = None

class NotificationCreate(NotificationBase):
    user_id: int

class NotificationRead(NotificationBase):
    id: str
    user_id: int
    is_read: bool
    is_sent: bool
    created_at: datetime
    read_at: Optional[datetime]
    
    class Config:
        from_attributes = True

# Response schemas
class SuccessResponse(BaseModel):
    success: bool = True
    message: str
    data: Optional[Dict[str, Any]] = None

class ErrorResponse(BaseModel):
    success: bool = False
    error: str
    details: Optional[Dict[str, Any]] = None

# Pagination schemas
class PaginatedResponse(BaseModel):
    items: List[Any]
    total: int
    page: int
    limit: int
    has_more: bool
    next_page: Optional[int] = None

# Media upload schemas
class MediaUploadResponse(BaseModel):
    url: str
    filename: str
    size: int
    content_type: str

# Provider integration schemas
class SponsoredPostCreate(PostBase):
    provider_id: str
    budget: float = Field(..., ge=0)
    target_audience: Optional[Dict[str, Any]] = None
    campaign_duration: Optional[int] = None  # days

class SponsoredPostRead(PostRead):
    budget: float
    target_audience: Optional[Dict[str, Any]]
    campaign_duration: Optional[int]
    impressions: int = 0
    clicks: int = 0
    conversions: int = 0

# Update forward references
CommentRead.model_rebuild()

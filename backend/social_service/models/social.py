# backend/social_service/models/social.py
import uuid
from sqlalchemy import Column, String, Integer, TIMESTAMP, func, Boolean, JSON, ForeignKey, Text, Index
from sqlalchemy.dialects.postgresql import UUID
from core.db import Base

class SocialPost(Base):
    __tablename__ = "posts"
    __table_args__ = {"schema": "social"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, nullable=False, index=True)
    provider_id = Column(String, index=True)  # Links to service providers
    
    # Content
    content = Column(Text, nullable=False)
    media_urls = Column(JSON, default=list)  # List of media URLs
    hashtags = Column(JSON, default=list)    # List of hashtags
    
    # Post metadata
    type = Column(String(50), default="text")  # text, image, video, carousel, poll, story
    is_sponsored = Column(Boolean, default=False)
    sponsored_by = Column(String)  # Provider ID if sponsored
    
    # Status and timestamps
    status = Column(String(50), default="published")  # draft, published, archived, deleted
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Indexes for performance
    __table_args__ = (
        Index('idx_posts_user_created', 'user_id', 'created_at'),
        Index('idx_posts_provider_created', 'provider_id', 'created_at'),
        Index('idx_posts_status_created', 'status', 'created_at'),
        Index('idx_posts_sponsored_created', 'is_sponsored', 'created_at'),
        {"schema": "social"}
    )

class SocialStory(Base):
    __tablename__ = "stories"
    __table_args__ = {"schema": "social"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, nullable=False, index=True)
    provider_id = Column(String, index=True)  # Links to service providers
    
    # Content
    content = Column(Text)
    media_url = Column(String)  # Single media URL for stories
    type = Column(String(50), default="image")  # image, video, text
    
    # Story metadata
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    expires_at = Column(TIMESTAMP(timezone=True), nullable=False)
    
    # Indexes for performance
    __table_args__ = (
        Index('idx_stories_user_created', 'user_id', 'created_at'),
        Index('idx_stories_expires', 'expires_at'),
        {"schema": "social"}
    )

class SocialComment(Base):
    __tablename__ = "comments"
    __table_args__ = {"schema": "social"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    post_id = Column(String, ForeignKey("social.posts.id"), nullable=False, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    
    # Comment content
    content = Column(Text, nullable=False)
    parent_id = Column(String, ForeignKey("social.comments.id"))  # For replies
    
    # Timestamps
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Indexes for performance
    __table_args__ = (
        Index('idx_comments_post_created', 'post_id', 'created_at'),
        Index('idx_comments_user_created', 'user_id', 'created_at'),
        Index('idx_comments_parent', 'parent_id'),
        {"schema": "social"}
    )

class SocialLike(Base):
    __tablename__ = "likes"
    __table_args__ = {"schema": "social"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, nullable=False, index=True)
    
    # Like target (either post or comment)
    post_id = Column(String, ForeignKey("social.posts.id"), index=True)
    comment_id = Column(String, ForeignKey("social.comments.id"), index=True)
    
    # Timestamp
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    
    # Ensure user can only like a post/comment once
    __table_args__ = (
        Index('idx_likes_user_post', 'user_id', 'post_id', unique=True),
        Index('idx_likes_user_comment', 'user_id', 'comment_id', unique=True),
        {"schema": "social"}
    )

class SocialShare(Base):
    __tablename__ = "shares"
    __table_args__ = {"schema": "social"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, nullable=False, index=True)
    post_id = Column(String, ForeignKey("social.posts.id"), nullable=False, index=True)
    
    # Share metadata
    message = Column(Text)  # Optional message with share
    shared_to = Column(String)  # Platform shared to (internal, facebook, twitter, etc.)
    
    # Timestamp
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    
    # Indexes for performance
    __table_args__ = (
        Index('idx_shares_user_created', 'user_id', 'created_at'),
        Index('idx_shares_post_created', 'post_id', 'created_at'),
        {"schema": "social"}
    )

class SocialFollow(Base):
    __tablename__ = "follows"
    __table_args__ = {"schema": "social"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    follower_id = Column(Integer, nullable=False, index=True)
    following_id = Column(Integer, nullable=False, index=True)
    
    # Timestamp
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    
    # Ensure unique follow relationships
    __table_args__ = (
        Index('idx_follows_unique', 'follower_id', 'following_id', unique=True),
        Index('idx_follows_follower', 'follower_id', 'created_at'),
        Index('idx_follows_following', 'following_id', 'created_at'),
        {"schema": "social"}
    )

class SocialStoryView(Base):
    __tablename__ = "story_views"
    __table_args__ = {"schema": "social"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    story_id = Column(String, ForeignKey("social.stories.id"), nullable=False, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    
    # View metadata
    viewed_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    
    # Ensure user can only view a story once
    __table_args__ = (
        Index('idx_story_views_unique', 'story_id', 'user_id', unique=True),
        Index('idx_story_views_story', 'story_id', 'viewed_at'),
        {"schema": "social"}
    )

class SocialPostAnalytics(Base):
    __tablename__ = "post_analytics"
    __table_args__ = {"schema": "social"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    post_id = Column(String, ForeignKey("social.posts.id"), nullable=False, unique=True, index=True)
    
    # Analytics metrics
    views = Column(Integer, default=0)
    likes = Column(Integer, default=0)
    comments = Column(Integer, default=0)
    shares = Column(Integer, default=0)
    
    # Timestamps
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Indexes for performance
    __table_args__ = (
        Index('idx_analytics_views', 'views'),
        Index('idx_analytics_likes', 'likes'),
        Index('idx_analytics_updated', 'updated_at'),
        {"schema": "social"}
    )

class SocialUserProfile(Base):
    __tablename__ = "user_profiles"
    __table_args__ = {"schema": "social"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, nullable=False, unique=True, index=True)
    
    # Profile information
    username = Column(String(50), unique=True, index=True)
    display_name = Column(String(100))
    bio = Column(Text)
    profile_image_url = Column(String)
    
    # Social stats
    followers_count = Column(Integer, default=0)
    following_count = Column(Integer, default=0)
    posts_count = Column(Integer, default=0)
    
    # Verification and provider status
    is_verified = Column(Boolean, default=False)
    is_provider = Column(Boolean, default=False)
    provider_id = Column(String, index=True)  # Links to service providers
    
    # Privacy settings
    is_private = Column(Boolean, default=False)
    allow_messages = Column(Boolean, default=True)
    
    # Timestamps
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Indexes for performance
    __table_args__ = (
        Index('idx_profiles_provider', 'provider_id'),
        Index('idx_profiles_verified', 'is_verified'),
        Index('idx_profiles_username', 'username'),
        {"schema": "social"}
    )

class SocialHashtag(Base):
    __tablename__ = "hashtags"
    __table_args__ = {"schema": "social"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(100), unique=True, nullable=False, index=True)
    
    # Usage statistics
    posts_count = Column(Integer, default=0)
    last_used = Column(TIMESTAMP(timezone=True), server_default=func.now())
    
    # Timestamps
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Indexes for performance
    __table_args__ = (
        Index('idx_hashtags_posts_count', 'posts_count'),
        Index('idx_hashtags_last_used', 'last_used'),
        {"schema": "social"}
    )

class SocialNotification(Base):
    __tablename__ = "notifications"
    __table_args__ = {"schema": "social"}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, nullable=False, index=True)
    
    # Notification content
    type = Column(String(50), nullable=False)  # like, comment, follow, mention, etc.
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    
    # Related entities
    related_user_id = Column(Integer, index=True)
    related_post_id = Column(String, index=True)
    related_comment_id = Column(String, index=True)
    
    # Status
    is_read = Column(Boolean, default=False)
    is_sent = Column(Boolean, default=False)
    
    # Timestamps
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    read_at = Column(TIMESTAMP(timezone=True))
    
    # Indexes for performance
    __table_args__ = (
        Index('idx_notifications_user_unread', 'user_id', 'is_read', 'created_at'),
        Index('idx_notifications_type', 'type', 'created_at'),
        {"schema": "social"}
    )

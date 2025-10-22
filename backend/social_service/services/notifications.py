# backend/social_service/services/notifications.py
import asyncio
import json
from typing import Dict, List, Optional
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import text
from core.db import get_db
from core.config import FCM_SERVER_KEY, EMAIL_SERVICE_URL
import httpx
import sys
import os

# Import Alert Service integration
from services.alert_integration import SocialNotificationService, NotificationChannel

class NotificationService:
    """Service for handling social notifications via Alert Service"""
    
    def __init__(self):
        self.alert_integration = SocialNotificationService()
    
    async def send_push_notification(
        self, 
        user_id: int, 
        title: str, 
        body: str, 
        data: Optional[Dict] = None,
        db: Session = None
    ):
        """Send push notification via Alert Service"""
        return await self.alert_integration.send_social_notification(
            user_id=user_id,
            title=title,
            message=body,
            channels=[NotificationChannel.PUSH],
            priority=2,
            action_url=data.get('action_url') if data else None
        )
    
    async def send_email_notification(
        self, 
        user_id: int, 
        subject: str, 
        body: str, 
        db: Session = None
    ):
        """Send email notification via Alert Service"""
        return await self.alert_integration.send_social_notification(
            user_id=user_id,
            title=subject,
            message=body,
            channels=[NotificationChannel.EMAIL],
            priority=2
        )
    
    async def send_sms_notification(
        self, 
        user_id: int, 
        message: str, 
        db: Session = None
    ):
        """Send SMS notification via Alert Service"""
        return await self.alert_integration.send_social_notification(
            user_id=user_id,
            title="Social Update",
            message=message,
            channels=[NotificationChannel.SMS],
            priority=1
        )
    
    # User data fetching is now handled by Alert Service
    # No need for duplicate methods here
    
    async def store_notification(
        self, 
        user_id: int, 
        title: str, 
        body: str, 
        data: Optional[Dict], 
        db: Session
    ):
        """Store notification in database"""
        try:
            db.execute(
                text("""
                    INSERT INTO social.notifications 
                    (id, user_id, type, title, message, data, is_read, is_sent, created_at)
                    VALUES (gen_random_uuid(), :user_id, :type, :title, :message, :data, false, true, NOW())
                """),
                {
                    "user_id": user_id,
                    "type": data.get("type", "general") if data else "general",
                    "title": title,
                    "message": body,
                    "data": json.dumps(data) if data else None
                }
            )
            db.commit()
        except Exception as e:
            print(f"Error storing notification: {str(e)}")
    
    # Notification templates
    async def notify_new_post(self, user_id: int, post_data: dict, db: Session):
        """Notify followers about new post"""
        title = "New Post from Following"
        body = f"{post_data.get('username', 'Someone')} shared a new post"
        
        await self.send_push_notification(user_id, title, body, {
            "type": "new_post",
            "post_id": post_data.get("id"),
            "user_id": post_data.get("user_id")
        }, db)
    
    async def notify_new_comment(self, user_id: int, comment_data: dict, db: Session):
        """Notify post owner about new comment"""
        title = "New Comment"
        body = f"{comment_data.get('username', 'Someone')} commented on your post"
        
        await self.send_push_notification(user_id, title, body, {
            "type": "new_comment",
            "comment_id": comment_data.get("id"),
            "post_id": comment_data.get("post_id")
        }, db)
    
    async def notify_new_like(self, user_id: int, like_data: dict, db: Session):
        """Notify content owner about new like"""
        title = "New Like"
        body = f"{like_data.get('username', 'Someone')} liked your post"
        
        await self.send_push_notification(user_id, title, body, {
            "type": "new_like",
            "post_id": like_data.get("post_id")
        }, db)
    
    async def notify_new_follow(self, user_id: int, follower_data: dict, db: Session):
        """Notify user about new follower"""
        title = "New Follower"
        body = f"{follower_data.get('username', 'Someone')} started following you"
        
        await self.send_push_notification(user_id, title, body, {
            "type": "new_follow",
            "follower_id": follower_data.get("id")
        }, db)
    
    async def notify_story_view(self, user_id: int, viewer_data: dict, db: Session):
        """Notify story owner about new view"""
        title = "Story View"
        body = f"{viewer_data.get('username', 'Someone')} viewed your story"
        
        await self.send_push_notification(user_id, title, body, {
            "type": "story_view",
            "story_id": viewer_data.get("story_id")
        }, db)

# Global notification service instance
notification_service = NotificationService()

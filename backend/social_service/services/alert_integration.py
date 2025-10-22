# backend/social_service/services/alert_integration.py
import httpx
import logging
from typing import List, Optional
from enum import Enum

logger = logging.getLogger(__name__)

class NotificationChannel(Enum):
    IN_APP = "IN_APP"
    PUSH = "PUSH"
    SMS = "SMS"
    EMAIL = "EMAIL"
    WHATSAPP = "WHATSAPP"

class SocialNotificationService:
    """Service for sending social notifications via Alert Service"""
    
    def __init__(self):
        self.alert_service_url = "http://alert-service:8006"
    
    async def send_social_notification(
        self, 
        user_id: int, 
        title: str, 
        message: str, 
        channels: List[NotificationChannel],
        priority: int = 1,
        action_url: Optional[str] = None,
        action_text: Optional[str] = None
    ) -> bool:
        """Send notification via Alert Service"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.alert_service_url}/notifications/send",
                    json={
                        "user_id": user_id,
                        "title": title,
                        "message": message,
                        "channels": [channel.value for channel in channels],
                        "priority": priority,
                        "action_url": action_url,
                        "action_text": action_text,
                        "notification_type": "SOCIAL_NOTIFICATION"
                    },
                    timeout=10.0
                )
                
                if response.status_code == 200:
                    result = response.json()
                    logger.info(f"Social notification sent successfully: {result}")
                    return result.get('success', False)
                else:
                    logger.error(f"Alert service error: {response.status_code} - {response.text}")
                    return False
                    
        except httpx.TimeoutException:
            logger.error("Timeout connecting to Alert Service")
            return False
        except Exception as e:
            logger.error(f"Error sending social notification: {str(e)}")
            return False
    
    async def send_comment_notification(
        self, 
        post_owner_id: int, 
        commenter_name: str, 
        post_id: str,
        comment_content: str
    ) -> bool:
        """Send notification for new comment"""
        return await self.send_social_notification(
            user_id=post_owner_id,
            title="New Comment",
            message=f"{commenter_name} commented: \"{comment_content[:50]}{'...' if len(comment_content) > 50 else ''}\"",
            channels=[NotificationChannel.PUSH, NotificationChannel.IN_APP],
            priority=2,
            action_url=f"/social/posts/{post_id}",
            action_text="View Comment"
        )
    
    async def send_like_notification(
        self, 
        post_owner_id: int, 
        liker_name: str, 
        post_id: str
    ) -> bool:
        """Send notification for new like"""
        return await self.send_social_notification(
            user_id=post_owner_id,
            title="New Like",
            message=f"{liker_name} liked your post",
            channels=[NotificationChannel.IN_APP],
            priority=1,
            action_url=f"/social/posts/{post_id}",
            action_text="View Post"
        )
    
    async def send_follow_notification(
        self, 
        user_id: int, 
        follower_name: str
    ) -> bool:
        """Send notification for new follow"""
        return await self.send_social_notification(
            user_id=user_id,
            title="New Follower",
            message=f"{follower_name} started following you",
            channels=[NotificationChannel.PUSH, NotificationChannel.IN_APP],
            priority=2,
            action_url="/social/profile",
            action_text="View Profile"
        )
    
    async def send_mention_notification(
        self, 
        user_id: int, 
        mentioner_name: str, 
        post_id: str,
        mention_content: str
    ) -> bool:
        """Send notification for mention in post"""
        return await self.send_social_notification(
            user_id=user_id,
            title="You were mentioned",
            message=f"{mentioner_name} mentioned you in a post",
            channels=[NotificationChannel.PUSH, NotificationChannel.IN_APP],
            priority=3,
            action_url=f"/social/posts/{post_id}",
            action_text="View Post"
        )
    
    async def send_story_view_notification(
        self, 
        story_owner_id: int, 
        viewer_name: str
    ) -> bool:
        """Send notification for story view (optional, low priority)"""
        return await self.send_social_notification(
            user_id=story_owner_id,
            title="Story View",
            message=f"{viewer_name} viewed your story",
            channels=[NotificationChannel.IN_APP],
            priority=1,
            action_url="/social/stories",
            action_text="View Stories"
        )

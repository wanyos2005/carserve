# backend/social_service/services/notification_helper.py
"""
Helper service for social service to call alert service for notifications
This replaces the old FCM service in social service
"""
import httpx
import logging
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)

class NotificationHelper:
    """Helper class to call alert service for notifications"""
    
    def __init__(self, alert_service_url: str = "http://alert-service:8006"):
        self.alert_service_url = alert_service_url
    
    async def send_social_notification(
        self,
        user_id: int,
        title: str,
        message: str,
        notification_type: str,
        data: Optional[Dict[str, Any]] = None,
        fcm_token: Optional[str] = None
    ) -> Dict[str, Any]:
        """Send social notification via alert service"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.alert_service_url}/alerts/social/send",
                    params={
                        "user_id": user_id,
                        "title": title,
                        "message": message,
                        "notification_type": notification_type,
                        "fcm_token": fcm_token
                    },
                    json=data or {},
                    timeout=10
                )
                response.raise_for_status()
                return response.json()
        except Exception as e:
            logger.error(f"Failed to send social notification: {str(e)}")
            return {"success": False, "error": str(e)}
    
    async def send_multicast_social_notification(
        self,
        user_ids: List[int],
        title: str,
        message: str,
        notification_type: str,
        data: Optional[Dict[str, Any]] = None,
        fcm_tokens: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """Send multicast social notification via alert service"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.alert_service_url}/alerts/social/multicast",
                    params={
                        "user_ids": user_ids,
                        "title": title,
                        "message": message,
                        "notification_type": notification_type,
                        "fcm_tokens": fcm_tokens
                    },
                    json=data or {},
                    timeout=10
                )
                response.raise_for_status()
                return response.json()
        except Exception as e:
            logger.error(f"Failed to send multicast social notification: {str(e)}")
            return {"success": False, "error": str(e)}
    
    async def send_new_post_notification(
        self,
        post_id: str,
        user_id: int,
        content: str,
        followers: List[int]
    ) -> Dict[str, Any]:
        """Send new post notification via alert service"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.alert_service_url}/alerts/social/new-post",
                    params={
                        "post_id": post_id,
                        "user_id": user_id,
                        "content": content,
                        "followers": followers
                    },
                    timeout=10
                )
                response.raise_for_status()
                return response.json()
        except Exception as e:
            logger.error(f"Failed to send new post notification: {str(e)}")
            return {"success": False, "error": str(e)}
    
    async def send_new_like_notification(
        self,
        post_id: str,
        liker_id: int,
        liker_name: str,
        post_owner_id: int
    ) -> Dict[str, Any]:
        """Send new like notification via alert service"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.alert_service_url}/alerts/social/new-like",
                    params={
                        "post_id": post_id,
                        "liker_id": liker_id,
                        "liker_name": liker_name,
                        "post_owner_id": post_owner_id
                    },
                    timeout=10
                )
                response.raise_for_status()
                return response.json()
        except Exception as e:
            logger.error(f"Failed to send new like notification: {str(e)}")
            return {"success": False, "error": str(e)}
    
    async def send_new_comment_notification(
        self,
        post_id: str,
        commenter_id: int,
        commenter_name: str,
        comment: str,
        post_owner_id: int
    ) -> Dict[str, Any]:
        """Send new comment notification via alert service"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.alert_service_url}/alerts/social/new-comment",
                    params={
                        "post_id": post_id,
                        "commenter_id": commenter_id,
                        "commenter_name": commenter_name,
                        "comment": comment,
                        "post_owner_id": post_owner_id
                    },
                    timeout=10
                )
                response.raise_for_status()
                return response.json()
        except Exception as e:
            logger.error(f"Failed to send new comment notification: {str(e)}")
            return {"success": False, "error": str(e)}

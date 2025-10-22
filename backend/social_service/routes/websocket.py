# backend/social_service/routes/websocket.py
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from typing import Dict, List
import json
import asyncio
from datetime import datetime
from core.db import get_db
from core.security import get_current_user_id
from sqlalchemy.orm import Session

router = APIRouter()

class ConnectionManager:
    """Manages WebSocket connections for real-time updates"""
    
    def __init__(self):
        # Active connections: {user_id: [websocket1, websocket2, ...]}
        self.active_connections: Dict[int, List[WebSocket]] = {}
        # User presence tracking
        self.user_presence: Dict[int, datetime] = {}
    
    async def connect(self, websocket: WebSocket, user_id: int):
        """Accept a new WebSocket connection"""
        await websocket.accept()
        
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        
        self.active_connections[user_id].append(websocket)
        self.user_presence[user_id] = datetime.now()
        
        # Notify user is online
        await self.broadcast_presence_update(user_id, "online")
        
        print(f"User {user_id} connected. Total connections: {len(self.active_connections[user_id])}")
    
    def disconnect(self, websocket: WebSocket, user_id: int):
        """Remove a WebSocket connection"""
        if user_id in self.active_connections:
            try:
                self.active_connections[user_id].remove(websocket)
                if not self.active_connections[user_id]:
                    del self.active_connections[user_id]
                    # Notify user is offline
                    asyncio.create_task(self.broadcast_presence_update(user_id, "offline"))
            except ValueError:
                pass
        
        print(f"User {user_id} disconnected. Remaining connections: {len(self.active_connections.get(user_id, []))}")
    
    async def send_personal_message(self, message: dict, user_id: int):
        """Send message to specific user"""
        if user_id in self.active_connections:
            dead_connections = []
            for websocket in self.active_connections[user_id]:
                try:
                    await websocket.send_text(json.dumps(message))
                except:
                    dead_connections.append(websocket)
            
            # Remove dead connections
            for websocket in dead_connections:
                self.active_connections[user_id].remove(websocket)
    
    async def broadcast_to_followers(self, message: dict, user_id: int, db: Session):
        """Broadcast message to user's followers"""
        # Get user's followers
        followers = db.execute(
            "SELECT follower_id FROM social.follows WHERE following_id = :user_id",
            {"user_id": user_id}
        ).fetchall()
        
        for follower in followers:
            follower_id = follower[0]
            await self.send_personal_message(message, follower_id)
    
    async def broadcast_presence_update(self, user_id: int, status: str):
        """Broadcast user presence update to followers"""
        message = {
            "type": "presence_update",
            "user_id": user_id,
            "status": status,
            "timestamp": datetime.now().isoformat()
        }
        
        # Get followers and notify them
        # This would need database access, so we'll implement it in the endpoint
        pass

# Global connection manager
manager = ConnectionManager()

@router.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: int):
    """WebSocket endpoint for real-time updates"""
    await manager.connect(websocket, user_id)
    
    try:
        while True:
            # Keep connection alive and handle incoming messages
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Handle different message types
            if message.get("type") == "ping":
                await websocket.send_text(json.dumps({
                    "type": "pong",
                    "timestamp": datetime.now().isoformat()
                }))
            elif message.get("type") == "typing":
                # Handle typing indicators
                await handle_typing_indicator(user_id, message)
            elif message.get("type") == "view_story":
                # Handle story view notifications
                await handle_story_view(user_id, message)
                
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
    except Exception as e:
        print(f"WebSocket error for user {user_id}: {str(e)}")
        manager.disconnect(websocket, user_id)

async def handle_typing_indicator(user_id: int, message: dict):
    """Handle typing indicators in comments"""
    target_user_id = message.get("target_user_id")
    if target_user_id:
        await manager.send_personal_message({
            "type": "typing_indicator",
            "user_id": user_id,
            "post_id": message.get("post_id"),
            "timestamp": datetime.now().isoformat()
        }, target_user_id)

async def handle_story_view(user_id: int, message: dict):
    """Handle story view notifications"""
    story_owner_id = message.get("story_owner_id")
    if story_owner_id and story_owner_id != user_id:
        await manager.send_personal_message({
            "type": "story_viewed",
            "viewer_id": user_id,
            "story_id": message.get("story_id"),
            "timestamp": datetime.now().isoformat()
        }, story_owner_id)

# Real-time notification functions
async def notify_new_post(user_id: int, post_data: dict, db: Session):
    """Notify followers about new post"""
    message = {
        "type": "new_post",
        "post": post_data,
        "timestamp": datetime.now().isoformat()
    }
    await manager.broadcast_to_followers(message, user_id, db)

async def notify_new_comment(post_owner_id: int, comment_data: dict):
    """Notify post owner about new comment"""
    message = {
        "type": "new_comment",
        "comment": comment_data,
        "timestamp": datetime.now().isoformat()
    }
    await manager.send_personal_message(message, post_owner_id)

async def notify_new_like(content_owner_id: int, like_data: dict):
    """Notify content owner about new like"""
    message = {
        "type": "new_like",
        "like": like_data,
        "timestamp": datetime.now().isoformat()
    }
    await manager.send_personal_message(message, content_owner_id)

async def notify_new_follow(user_id: int, follower_data: dict):
    """Notify user about new follower"""
    message = {
        "type": "new_follow",
        "follower": follower_data,
        "timestamp": datetime.now().isoformat()
    }
    await manager.send_personal_message(message, user_id)

async def notify_story_view(story_owner_id: int, viewer_data: dict):
    """Notify story owner about new view"""
    message = {
        "type": "story_viewed",
        "viewer": viewer_data,
        "timestamp": datetime.now().isoformat()
    }
    await manager.send_personal_message(message, story_owner_id)

# Presence tracking
@router.get("/presence/{user_id}")
async def get_user_presence(user_id: int):
    """Get user's online status"""
    is_online = user_id in manager.active_connections
    last_seen = manager.user_presence.get(user_id)
    
    return {
        "user_id": user_id,
        "is_online": is_online,
        "last_seen": last_seen.isoformat() if last_seen else None
    }

@router.get("/online-users")
async def get_online_users():
    """Get list of online users"""
    online_users = list(manager.active_connections.keys())
    return {
        "online_users": online_users,
        "count": len(online_users)
    }

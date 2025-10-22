# 🎯 **Strategic Refactoring Plan**
## Making Alert Service the Central Notification Hub

---

## 🏗️ **Current Architecture Analysis**

### **Alert Service (Backbone) - ✅ ESTABLISHED**
- ✅ **FastAPI Email**: Working with SMTP/Gmail
- ✅ **Africa's Talking SMS**: Working with AT API
- ✅ **Twilio SMS**: Working with Twilio API
- ✅ **Database Schema**: Complete with alerts, rules, preferences
- ✅ **API Endpoints**: `/alerts`, `/rules`, `/notifications`
- ❌ **Push Notifications**: Missing FCM integration
- ✅ **Multi-Channel Support**: IN_APP, PUSH, SMS, EMAIL, WHATSAPP

### **Social Service (New) - ❌ DUPLICATING**
- ❌ **Email**: Duplicating alert service logic
- ❌ **SMS**: Duplicating alert service logic  
- ❌ **Push**: Implementing FCM (should be in alert service)
- ❌ **User Data**: Duplicating user fetching logic

---

## 🎯 **Refactoring Strategy: Alert Service as Central Hub**

### **Phase 1: Complete Alert Service Push Integration** 🚀
**Goal**: Make Alert Service the **complete notification backbone**

#### **1.1 Add FCM to Alert Service**
```python
# backend/alert_service/services/notification_service.py
async def _send_push_notification(self, alert: Alert):
    """Send push notification via FCM - COMPLETE IMPLEMENTATION"""
    try:
        # Get user's FCM tokens from user service
        user_tokens = await self._get_user_fcm_tokens(alert.user_id)
        if not user_tokens:
            logger.warning(f"No FCM tokens found for user {alert.user_id}")
            return
            
        # Prepare FCM payload
        payload = {
            "registration_ids": user_tokens,
            "notification": {
                "title": alert.title,
                "body": alert.message,
                "icon": "ic_notification",
                "click_action": alert.action_url or "FLUTTER_NOTIFICATION_CLICK"
            },
            "data": {
                "alert_id": alert.id,
                "type": alert.type.value,
                "priority": str(alert.priority),
                "action_url": alert.action_url or "",
                "action_text": alert.action_text or ""
            }
        }
        
        # Send via FCM
        response = await self._send_fcm_notification(payload)
        if response.get('success'):
            logger.info(f"Push notification sent for alert {alert.id}")
        else:
            raise Exception(f"FCM error: {response.get('error')}")
            
    except Exception as e:
        logger.error(f"Failed to send push notification: {str(e)}")
        raise
```

#### **1.2 Add Generic Notification API**
```python
# backend/alert_service/routes/notifications.py
@router.post("/send", response_model=NotificationResponse)
async def send_notification(
    notification: NotificationRequest,
    db: Session = Depends(get_db)
):
    """Generic notification endpoint for other services"""
    try:
        # Create alert-like object for processing
        alert_data = {
            "user_id": notification.user_id,
            "title": notification.title,
            "message": notification.message,
            "channels": notification.channels,
            "priority": notification.priority,
            "action_url": notification.action_url,
            "action_text": notification.action_text,
            "type": "SOCIAL_NOTIFICATION"  # New type for social
        }
        
        # Process through existing alert system
        result = await notification_service.send_alert(alert_data)
        return NotificationResponse(success=result)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

### **Phase 2: Social Service Integration** 🔄
**Goal**: Make Social Service use Alert Service for all notifications

#### **2.1 Remove Duplicate Notification Code**
```python
# backend/social_service/services/notifications.py
# DELETE: All duplicate notification methods
# DELETE: FCM, Email, SMS implementations
# DELETE: User data fetching methods

# REPLACE WITH: Alert Service integration
class SocialNotificationService:
    def __init__(self):
        self.alert_service_url = "http://alert-service:8003"
    
    async def send_social_notification(
        self, 
        user_id: int, 
        title: str, 
        message: str, 
        channels: List[str],
        priority: str = "MEDIUM",
        action_url: str = None
    ):
        """Send notification via Alert Service"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.alert_service_url}/notifications/send",
                    json={
                        "user_id": user_id,
                        "title": title,
                        "message": message,
                        "channels": channels,
                        "priority": priority,
                        "action_url": action_url,
                        "type": "SOCIAL_NOTIFICATION"
                    }
                )
                return response.status_code == 200
        except Exception as e:
            print(f"Error sending notification: {str(e)}")
            return False
```

#### **2.2 Update Social Service Routes**
```python
# backend/social_service/routes/interactions.py
# Replace notification calls with Alert Service integration

# OLD:
# await notification_service.send_push_notification(...)

# NEW:
await social_notification_service.send_social_notification(
    user_id=user_id,
    title="New Comment",
    message=f"{commenter_name} commented on your post",
    channels=["PUSH", "IN_APP"],
    priority="MEDIUM",
    action_url=f"/social/posts/{post_id}"
)
```

### **Phase 3: Centralized Configuration** ⚙️
**Goal**: Single source of truth for all notification settings

#### **3.1 Alert Service Configuration (Master)**
```python
# backend/alert_service/core/config.py
class Settings(BaseSettings):
    # Existing config stays the same
    # Add social service integration
    SOCIAL_SERVICE_URL: str = os.getenv("SOCIAL_SERVICE_URL", "http://social-service:8008")
    
    # Notification types for social
    SOCIAL_NOTIFICATION_TYPES: List[str] = [
        "NEW_COMMENT",
        "NEW_LIKE", 
        "NEW_FOLLOW",
        "POST_MENTION",
        "STORY_VIEW"
    ]
```

#### **3.2 Social Service Configuration (Minimal)**
```python
# backend/social_service/core/config.py
class Settings(BaseSettings):
    # Remove all notification configs
    # Keep only social-specific configs
    ALERT_SERVICE_URL: str = os.getenv("ALERT_SERVICE_URL", "http://alert-service:8003")
    
    # Remove: FCM_SERVER_KEY, SMTP_*, TWILIO_*, AT_*
```

---

## 📊 **Benefits of This Approach**

### **1. Single Source of Truth** ✅
- **Alert Service**: Master notification system
- **All Services**: Use Alert Service for notifications
- **Configuration**: One place for all notification settings

### **2. No Code Duplication** ✅
- **Before**: 500+ lines of duplicate code
- **After**: 0 lines of duplicate code
- **Maintenance**: Fix bugs in one place

### **3. Consistent Behavior** ✅
- **All Services**: Same notification behavior
- **All Channels**: Same email, SMS, push logic
- **All Users**: Same notification experience

### **4. Easy Scaling** ✅
- **Add New Channel**: Update Alert Service once
- **All Services**: Automatically get new channel
- **New Service**: Just integrate with Alert Service

---

## 🚀 **Implementation Steps**

### **Step 1: Complete Alert Service** (1-2 hours)
1. Add FCM integration to Alert Service
2. Add generic notification API endpoint
3. Test all channels work

### **Step 2: Refactor Social Service** (1 hour)
1. Remove duplicate notification code
2. Add Alert Service integration
3. Update all notification calls

### **Step 3: Update Configuration** (30 minutes)
1. Remove notification configs from Social Service
2. Add Alert Service URL to Social Service
3. Test integration

### **Step 4: Test & Deploy** (30 minutes)
1. Test all notification channels
2. Test social service notifications
3. Deploy changes

---

## 🎯 **Result: Professional Architecture**

```
┌─────────────────────────────────────────────────────────┐
│                Alert Service (Master)                  │
│  ✅ Email (FastAPI Mail)                              │
│  ✅ SMS (Africa's Talking + Twilio)                   │
│  ✅ Push (FCM) - TO BE ADDED                          │
│  ✅ WhatsApp (Placeholder)                            │
│  ✅ In-App (Database)                                 │
│  ✅ Generic API for Other Services                     │
└─────────────────────────────────────────────────────────┘
           │                    │                    │
           ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────┐
│  Social Service    │  User Service    │  Other Services │
│  - Uses Alert API  │  - Uses Alert API │  - Uses Alert API │
│  - No Duplication │  - No Duplication │  - No Duplication │
│  - Focus on Logic │  - Focus on Logic │  - Focus on Logic │
└─────────────────────────────────────────────────────────┘
```

**This approach makes Alert Service the backbone while eliminating all duplication!** 🚀

# FCM Token Retry Solution

## Current Behavior (What You Identified)

You're absolutely correct! Here's what happens:

### Current Flow:
1. **Service logged** → Alert created for `guest_user_id=10`
2. **Celery task triggered immediately** → `deliver_alert(alert.id)` runs
3. **Push notification attempt**:
   - Looks up FCM token for `guest_user_id=10`
   - ❌ **No token found** (guest hasn't logged in yet)
   - Logs as FAILED, returns gracefully
4. **In-app notification**:
   - ✅ Always succeeds (stored in database)
5. **Alert status**: Set to DELIVERED (because IN_APP succeeded)

### Result:
- ✅ **In-app alert works**: Guest user will see it when they log in
- ❌ **Push notification missed**: No push notification when guest logs in later

---

## The Problem

When the guest user logs in **after** the alert is created:
- FCM token is registered
- But the alert delivery already ran and failed for push
- No retry mechanism to send push notification when token becomes available

---

## Solutions

### Option 1: **Delay Push Notifications** (Recommended for MVP)

Only attempt push notification if FCM token exists, otherwise skip and mark for later retry.

**Implementation:**
- Check if token exists before attempting push
- If no token, mark alert as `PENDING` for push (not FAILED)
- When user logs in, trigger retry for pending alerts with push channel

### Option 2: **Retry Queue** (More Robust)

Create a retry mechanism that checks for pending alerts when a user's FCM token is registered.

**Implementation:**
- When FCM token is registered (`POST /users/{user_id}/fcm-token`)
- Trigger a background task to check for pending alerts for that user
- Retry push notifications for alerts with status `PENDING` or `SENT` that failed push delivery

### Option 3: **Hybrid Approach** (Best for Production)

Combine both:
1. Don't mark alert as fully DELIVERED if push channel failed due to missing token
2. Keep alert status as `PENDING` or `SENT` (not DELIVERED)
3. When user logs in and registers FCM token, trigger retry
4. Retry logic checks for alerts with:
   - Status: `PENDING` or `SENT`
   - Has push channel in `channels`
   - Push notification failed due to missing token
   - Created within last 7 days (configurable)

---

## Recommended Implementation: Option 3

### Step 1: Modify Push Notification Handler

Change `_send_push_notification` to not mark as FAILED if token is missing, but mark as "pending retry":

```python
async def _send_push_notification(self, alert: Alert):
    """Send push notification via FCM"""
    try:
        user_token = await self._get_user_fcm_token(alert.user_id)
        if not user_token:
            logger.info(f"No FCM token found for user {alert.user_id}, will retry when token is registered")
            # Don't log as FAILED - mark for retry instead
            # Keep alert status as PENDING or SENT, not DELIVERED
            return  # Skip push, but don't fail the entire alert
        
        # ... rest of push notification code
```

### Step 2: Add Retry Trigger on FCM Token Registration

When user registers FCM token, trigger retry for pending alerts:

```python
# In user_service/routes/users.py
@router.post("/{user_id}/fcm-token")
def register_fcm_token_alias(...):
    # Register token
    result = register_fcm_token(user_id, token_request, db)
    
    # Trigger retry for pending alerts
    try:
        alert_service_url = os.getenv("ALERT_SERVICE_URL", "http://alert-service:8006")
        with httpx.Client(timeout=3.0) as client:
            client.post(f"{alert_service_url}/alerts/retry-push/{user_id}")
    except Exception:
        pass  # Don't fail token registration if retry fails
    
    return result
```

### Step 3: Add Retry Endpoint

```python
# In alert_service/routes/alerts.py
@router.post("/retry-push/{user_id}")
async def retry_push_for_user(user_id: int, db: Session = Depends(get_db)):
    """Retry push notifications for user when FCM token becomes available"""
    service = AlertService(db)
    alerts = await service.get_alerts(
        user_id=user_id,
        status=AlertStatus.PENDING,  # or SENT
        limit=50
    )
    
    # Filter alerts that have push channel but failed push delivery
    for alert in alerts:
        if AlertChannel.PUSH in alert.channels:
            # Check if push failed due to missing token
            from models.alert import NotificationLog
            push_log = db.query(NotificationLog).filter(
                NotificationLog.alert_id == alert.id,
                NotificationLog.channel == AlertChannel.PUSH,
                NotificationLog.status == AlertStatus.FAILED
            ).first()
            
            if push_log and "No FCM token" in (push_log.error_message or ""):
                # Retry push notification
                celery_app.send_task("deliver_alert", args=[alert.id])
    
    return {"message": f"Retry triggered for {len(alerts)} alerts"}
```

---

## Quick Fix for Testing (No Code Changes)

For now, you can test with this workaround:

### Test Scenario That Works:
1. ✅ **Login as Guest User FIRST** (registers FCM token)
2. ✅ **Login as Provider**
3. ✅ **Perform bulk service log** (creates alert)
4. ✅ **Guest user receives push notification immediately** ✅

### Test Scenario That Partially Works:
1. ✅ **Login as Provider**
2. ✅ **Perform bulk service log** (creates alert)
3. ✅ **Login as Guest User** (registers FCM token)
4. ❌ **Push notification won't be sent** (already attempted and skipped)
5. ✅ **But guest user WILL see in-app alert** when they fetch alerts

---

## Summary

**You're correct** - if the guest user logs in after the alert is created, the push notification will have already been attempted and failed silently.

**Current behavior:**
- ✅ In-app alerts always work (stored in DB)
- ❌ Push notifications fail silently if user hasn't logged in yet

**Recommended solution:**
- Implement retry mechanism when FCM token is registered
- Or test with guest user logging in first

**For immediate testing:**
- Login as guest user first, then perform service log
- This ensures FCM token exists when alert is created


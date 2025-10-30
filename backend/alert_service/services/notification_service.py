# backend/alert_service/services/notification_service.py
from sqlalchemy.orm import Session
from typing import List, Dict, Any
import requests
import logging
from datetime import datetime

from models.alert import Alert, AlertChannel, AlertStatus, NotificationLog
from services.alert_service import AlertService

logger = logging.getLogger(__name__)

class NotificationService:
    def __init__(self, db: Session):
        self.db = db
        self.alert_service = AlertService(db)
        self._fcm_initialized = False

    async def send_alert(self, alert: Alert) -> bool:
        """Send alert through all configured channels"""
        # Normalize channels to AlertChannel enums if they were stored as strings
        try:
            channels: list[AlertChannel] = [
                (AlertChannel(c) if isinstance(c, str) else c)
                for c in (alert.channels or [])
            ]
        except Exception:
            channels = []
        
        if not channels:
            logger.warning(f"No channels configured for alert {alert.id}")
            return False
        
        # Try all channels and collect results
        for channel in channels:
            try:
                if channel == AlertChannel.IN_APP:
                    await self._send_in_app_notification(alert)
                elif channel == AlertChannel.PUSH:
                    await self._send_push_notification(alert)
                elif channel == AlertChannel.SMS:
                    await self._send_sms_notification(alert)
                elif channel == AlertChannel.EMAIL:
                    await self._send_email_notification(alert)
                elif channel == AlertChannel.WHATSAPP:
                    await self._send_whatsapp_notification(alert)
                    
            except Exception as e:
                logger.warning(f"Failed to send {channel} notification for alert {alert.id}: {str(e)}")
                # Continue to next channel instead of stopping
                continue
        
        # Check notification logs to determine actual success
        # Count successful deliveries by checking the logs
        from models.alert import NotificationLog
        successful_deliveries = self.db.query(NotificationLog).filter(
            NotificationLog.alert_id == alert.id,
            NotificationLog.status == AlertStatus.SENT
        ).count()
        
        overall_success = successful_deliveries > 0
        
        if overall_success:
            logger.info(f"Alert {alert.id} delivered successfully via {successful_deliveries}/{len(channels)} channels")
        else:
            logger.error(f"Alert {alert.id} failed to deliver via all {len(channels)} channels")
            
        return overall_success
    
    async def _log_notification(
        self, 
        alert: Alert, 
        channel: AlertChannel, 
        status: AlertStatus, 
        external_id: str = None, 
        external_response: Dict = None, 
        error_message: str = None
    ):
        """Log notification delivery attempt"""
        try:
            notification_log = NotificationLog(
                alert_id=alert.id,
                user_id=alert.user_id,
                channel=channel,
                status=status,
                external_id=external_id,
                external_response=external_response,
                error_message=error_message,
                sent_at=datetime.utcnow()
            )
            
            self.db.add(notification_log)
            self.db.commit()
            logger.info(f"Logged {channel} notification for alert {alert.id} with status {status}")
            
        except Exception as e:
            logger.error(f"Failed to log notification: {str(e)}")
            # Don't raise - logging failure shouldn't break notification flow

    async def _send_in_app_notification(self, alert: Alert):
        """Send in-app notification (store in database for app to fetch)"""
        try:
            # In-app notifications are handled by the app polling the alerts endpoint
            # This method can be used for additional processing if needed
            logger.info(f"In-app notification created for alert {alert.id}")
            
            # Log successful in-app notification
            await self._log_notification(
                alert=alert,
                channel=AlertChannel.IN_APP,
                status=AlertStatus.SENT
            )
            
        except Exception as e:
            logger.error(f"Failed to create in-app notification: {str(e)}")
            await self._log_notification(
                alert=alert,
                channel=AlertChannel.IN_APP,
                status=AlertStatus.FAILED,
                error_message=str(e)
            )
            raise

    async def _send_push_notification(self, alert: Alert):
        """Send push notification via FCM"""
        try:
            # Get user's FCM token from user service
            user_token = await self._get_user_fcm_token(alert.user_id)
            if not user_token:
                logger.warning(f"No FCM token found for user {alert.user_id}")
                # Log as skipped due to missing data
                await self._log_notification(
                    alert=alert,
                    channel=AlertChannel.PUSH,
                    status=AlertStatus.FAILED,
                    error_message="No FCM token found for user"
                )
                return
                
            # Prepare FCM payload
            payload = {
                "to": user_token,
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
                
                # Log successful push notification
                await self._log_notification(
                    alert=alert,
                    channel=AlertChannel.PUSH,
                    status=AlertStatus.SENT,
                    external_id=response.get('response', {}).get('message_id'),
                    external_response=response.get('response')
                )
            else:
                error_msg = f"FCM error: {response.get('error')}"
                await self._log_notification(
                    alert=alert,
                    channel=AlertChannel.PUSH,
                    status=AlertStatus.FAILED,
                    error_message=error_msg
                )
                raise Exception(error_msg)
                
        except Exception as e:
            logger.error(f"Failed to send push notification: {str(e)}")
            await self._log_notification(
                alert=alert,
                channel=AlertChannel.PUSH,
                status=AlertStatus.FAILED,
                error_message=str(e)
            )
            raise

    async def _send_sms_notification(self, alert: Alert):
        """Send SMS notification via configured provider (Twilio or Africa's Talking)"""
        try:
            # Get user's phone number from user service
            user_phone = await self._get_user_phone(alert.user_id)
            if not user_phone:
                logger.warning(f"No phone number found for user {alert.user_id}")
                # Log as skipped due to missing data
                await self._log_notification(
                    alert=alert,
                    channel=AlertChannel.SMS,
                    status=AlertStatus.FAILED,
                    error_message="No phone number found for user"
                )
                return
                
            # Prepare SMS message
            message = f"{alert.title}\n\n{alert.message}"
            if alert.action_url:
                message += f"\n\nAction: {alert.action_url}"
                
            # Normalize phone (basic KE handling)
            phone = str(user_phone).strip()
            if phone.startswith("0"):
                phone = "+254" + phone[1:]
            elif phone.startswith("254") and not phone.startswith("+254"):
                phone = "+" + phone

            # Route to provider
            from core.config import settings
            provider = (settings.SMS_PROVIDER or "").lower()
            if provider == "africastalking":
                response = await self._send_africastalking_sms(phone, message)
            else:
                response = await self._send_twilio_sms(phone, message)
            if response.get('success'):
                logger.info(f"SMS sent for alert {alert.id}")
                
                # Log successful SMS notification
                await self._log_notification(
                    alert=alert,
                    channel=AlertChannel.SMS,
                    status=AlertStatus.SENT,
                    external_id=response.get('message_sid') or response.get('response', {}).get('SMSMessageData', {}).get('Recipients', [{}])[0].get('messageId'),
                    external_response=response
                )
            else:
                error_msg = f"SMS provider error: {response.get('error')}"
                await self._log_notification(
                    alert=alert,
                    channel=AlertChannel.SMS,
                    status=AlertStatus.FAILED,
                    error_message=error_msg
                )
                raise Exception(error_msg)
                
        except Exception as e:
            logger.error(f"Failed to send SMS: {str(e)}")
            await self._log_notification(
                alert=alert,
                channel=AlertChannel.SMS,
                status=AlertStatus.FAILED,
                error_message=str(e)
            )
            raise

    async def _send_email_notification(self, alert: Alert):
        """Send email notification"""
        try:
            # Get user's email from user service
            user_email = await self._get_user_email(alert.user_id)
            if not user_email:
                logger.warning(f"No email found for user {alert.user_id}")
                # Log as skipped due to missing data
                await self._log_notification(
                    alert=alert,
                    channel=AlertChannel.EMAIL,
                    status=AlertStatus.FAILED,
                    error_message="No email found for user"
                )
                return
                
            # Prepare email content
            subject = alert.title
            body = self._create_email_body(alert)
            
            # Send email
            response = await self._send_email(user_email, subject, body)
            if response.get('success'):
                logger.info(f"Email sent for alert {alert.id}")
                
                # Log successful email notification
                await self._log_notification(
                    alert=alert,
                    channel=AlertChannel.EMAIL,
                    status=AlertStatus.SENT,
                    external_response=response
                )
            else:
                error_msg = f"Email error: {response.get('error')}"
                await self._log_notification(
                    alert=alert,
                    channel=AlertChannel.EMAIL,
                    status=AlertStatus.FAILED,
                    error_message=error_msg
                )
                raise Exception(error_msg)
                
        except Exception as e:
            logger.error(f"Failed to send email: {str(e)}")
            await self._log_notification(
                alert=alert,
                channel=AlertChannel.EMAIL,
                status=AlertStatus.FAILED,
                error_message=str(e)
            )
            raise

    async def _send_whatsapp_notification(self, alert: Alert):
        """Send WhatsApp notification (placeholder for future implementation)"""
        try:
            # WhatsApp Business API integration can be added here
            logger.info(f"WhatsApp notification placeholder for alert {alert.id}")
            
            # Log WhatsApp notification as sent (placeholder)
            await self._log_notification(
                alert=alert,
                channel=AlertChannel.WHATSAPP,
                status=AlertStatus.SENT,
                external_response={"status": "placeholder_implementation"}
            )
            
        except Exception as e:
            logger.error(f"Failed to send WhatsApp notification: {str(e)}")
            await self._log_notification(
                alert=alert,
                channel=AlertChannel.WHATSAPP,
                status=AlertStatus.FAILED,
                error_message=str(e)
            )
            raise

    # =====================
    # Topic operations
    # =====================

    async def broadcast_to_topic(
        self,
        topic: str,
        title: str,
        message: str,
        data: Dict[str, Any] | None = None,
        image_url: str | None = None,
    ) -> Dict[str, Any]:
        """Broadcast a notification to an FCM topic via FCMService."""
        try:
            if not await self._ensure_fcm_initialized():
                return {"success": False, "error": "FCM not initialized"}
            from services.fcm_service import FCMService
            result = FCMService.send_topic_notification(
                topic=topic,
                title=title,
                body=message,
                data=data,
                image_url=image_url,
            )
            return result
        except Exception as e:
            return {"success": False, "error": str(e)}

    async def subscribe_tokens_to_topic(self, topic: str, tokens: list[str]) -> Dict[str, Any]:
        try:
            if not await self._ensure_fcm_initialized():
                return {"success": False, "error": "FCM not initialized"}
            from services.fcm_service import FCMService
            return FCMService.subscribe_to_topic(tokens, topic)
        except Exception as e:
            return {"success": False, "error": str(e)}

    async def unsubscribe_tokens_from_topic(self, topic: str, tokens: list[str]) -> Dict[str, Any]:
        try:
            if not await self._ensure_fcm_initialized():
                return {"success": False, "error": "FCM not initialized"}
            from services.fcm_service import FCMService
            return FCMService.unsubscribe_from_topic(tokens, topic)
        except Exception as e:
            return {"success": False, "error": str(e)}

    async def _get_user_fcm_token(self, user_id: int) -> str:
        """Get user's FCM token from user service"""
        try:
            import aiohttp
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{self._get_user_service_url()}/users/{user_id}/fcm-token", timeout=5) as response:
                    if response.status == 200:
                        data = await response.json()
                        return data.get('fcm_token')
        except Exception as e:
            logger.error(f"Failed to get FCM token for user {user_id}: {str(e)}")
        return None

    async def _get_user_phone(self, user_id: int) -> str:
        """Get user's phone number from user service"""
        try:
            import aiohttp
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{self._get_user_service_url()}/users/{user_id}", timeout=5) as response:
                    if response.status == 200:
                        data = await response.json()
                        return data.get('phone')
        except Exception as e:
            logger.error(f"Failed to get phone for user {user_id}: {str(e)}")
        return None

    async def _get_user_email(self, user_id: int) -> str:
        """Get user's email from user service"""
        try:
            import aiohttp
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{self._get_user_service_url()}/users/{user_id}", timeout=5) as response:
                    if response.status == 200:
                        data = await response.json()
                        return data.get('email')
        except Exception as e:
            logger.error(f"Failed to get email for user {user_id}: {str(e)}")
        return None

    async def _send_fcm_notification(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Send notification via Firebase Cloud Messaging V1 API"""
        try:
            from core.config import settings
            from services.fcm_service import FCMService
            
            # Initialize FCM service if not already done
            if not FCMService.is_initialized():
                if not FCMService.initialize(
                    project_id=settings.FCM_PROJECT_ID,
                    private_key=settings.FCM_PRIVATE_KEY,
                    client_email=settings.FCM_CLIENT_EMAIL
                ):
                    return {'success': False, 'error': 'Failed to initialize FCM service'}
            
            # Extract data from payload
            token = payload.get('to')
            notification_data = payload.get('notification', {})
            data = payload.get('data', {})
            
            if not token:
                return {'success': False, 'error': 'No FCM token provided'}
            
            # Send notification using FCM V1 API
            result = FCMService.send_notification(
                token=token,
                title=notification_data.get('title', ''),
                body=notification_data.get('body', ''),
                data=data,
                image_url=notification_data.get('icon')
            )
            
            return result
                
        except Exception as e:
            return {'success': False, 'error': str(e)}

    async def _send_twilio_sms(self, phone: str, message: str) -> Dict[str, Any]:
        """Send SMS via Twilio"""
        try:
            from core.config import settings
            from twilio.rest import Client
            
            client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
            
            message_obj = client.messages.create(
                body=message,
                from_=settings.TWILIO_PHONE_NUMBER,
                to=phone
            )
            
            return {'success': True, 'message_sid': message_obj.sid}
            
        except Exception as e:
            return {'success': False, 'error': str(e)}

    async def _send_africastalking_sms(self, phone: str, message: str) -> Dict[str, Any]:
        """Send SMS via Africa's Talking"""
        try:
            from core.config import settings
            import africastalking
            username = settings.AT_USERNAME
            api_key = settings.AT_API_KEY
            sender_id = settings.AT_SENDER_ID or None

            if not username or not api_key:
                return {'success': False, 'error': 'Africa\'s Talking credentials missing'}

            africastalking.initialize(username, api_key)
            sms = africastalking.SMS
            # SDK signature: send(message, recipients, sender_id=None, ...)
            if sender_id:
                response = sms.send(message, [phone], sender_id=sender_id)
            else:
                response = sms.send(message, [phone])
            # Basic success check
            # Response format: {'SMSMessageData': {'Message': 'Sent to 1/1 Total Cost: ...', 'Recipients': [...]}}
            if isinstance(response, dict) and 'SMSMessageData' in response:
                return {'success': True, 'response': response}
            return {'success': False, 'error': str(response)}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    async def _send_email(self, email: str, subject: str, body: str) -> Dict[str, Any]:
        """Send email notification using same config as user service"""
        try:
            from fastapi_mail import FastMail, MessageSchema, ConnectionConfig
            from core.config import settings
            
            # Use same email config as user service
            conf = ConnectionConfig(
                MAIL_USERNAME=settings.SMTP_USERNAME,
                MAIL_PASSWORD=settings.SMTP_PASSWORD,
                MAIL_FROM=settings.SMTP_FROM_EMAIL,
                MAIL_PORT=settings.SMTP_PORT,
                MAIL_SERVER=settings.SMTP_HOST,
                MAIL_FROM_NAME=settings.SMTP_FROM_NAME,
                MAIL_SSL_TLS=settings.SMTP_SSL,
                MAIL_STARTTLS=settings.SMTP_TLS,
                USE_CREDENTIALS=True,
                VALIDATE_CERTS=True
            )
            
            message = MessageSchema(
                subject=subject,
                recipients=[email],
                body=body,
                subtype="html"
            )
            
            fm = FastMail(conf)
            await fm.send_message(message)
            
            return {'success': True}
            
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _create_email_body(self, alert: Alert) -> str:
        """Create HTML email body for alert"""
        return f"""
        <html>
        <body>
            <h2>{alert.title}</h2>
            <p>{alert.message}</p>
            {f'<p><a href="{alert.action_url}" style="background-color: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">{alert.action_text or "Take Action"}</a></p>' if alert.action_url else ''}
            <hr>
            <p><small>This is an automated message from Our App. You can manage your notification preferences in the app settings.</small></p>
        </body>
        </html>
        """

    def _get_user_service_url(self) -> str:
        """Get user service URL from config"""
        from core.config import settings
        return settings.USER_SERVICE_URL

    # =============================================================================
    # SOCIAL NOTIFICATION METHODS (Centralized)
    # =============================================================================
    
    async def send_social_notification(
        self,
        user_id: int,
        title: str,
        message: str,
        notification_type: str,
        data: dict = None,
        fcm_token: str = None
    ) -> dict:
        """Send social notification (likes, comments, follows, etc.)"""
        try:
            # Ensure FCM is initialized
            if not await self._ensure_fcm_initialized():
                return {
                    'success': False,
                    'error': 'FCM service not initialized',
                    'message': 'Failed to send social notification'
                }
            
            # Get FCM token if not provided
            if not fcm_token:
                fcm_token = await self._get_user_fcm_token(user_id)
                if not fcm_token:
                    return {
                        'success': False,
                        'error': 'No FCM token found for user',
                        'message': 'Failed to send social notification'
                    }
            
            # Prepare social data
            social_data = data or {}
            social_data.update({
                'type': notification_type,
                'click_action': 'FLUTTER_NOTIFICATION_CLICK'
            })
            
            # Send FCM notification
            result = await self._send_fcm_notification({
                'to': fcm_token,
                'notification': {
                    'title': title,
                    'body': message,
                    'icon': 'ic_notification'
                },
                'data': social_data
            })
            
            if result['success']:
                logger.info(f"Social notification sent successfully: {result.get('message_id')}")
                return {
                    'success': True,
                    'message_id': result.get('message_id'),
                    'message': 'Social notification sent successfully'
                }
            else:
                logger.error(f"Failed to send social notification: {result.get('error')}")
                return {
                    'success': False,
                    'error': result.get('error'),
                    'message': 'Failed to send social notification'
                }
                
        except Exception as e:
            logger.error(f"Failed to send social notification: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'message': 'Failed to send social notification'
            }
    
    async def send_multicast_social_notification(
        self,
        user_ids: list,
        title: str,
        message: str,
        notification_type: str,
        data: dict = None,
        fcm_tokens: list = None
    ) -> dict:
        """Send social notification to multiple users"""
        try:
            # Ensure FCM is initialized
            if not await self._ensure_fcm_initialized():
                return {
                    'success': False,
                    'error': 'FCM service not initialized',
                    'message': 'Failed to send multicast social notification'
                }
            
            # Get FCM tokens if not provided
            if not fcm_tokens:
                fcm_tokens = []
                for user_id in user_ids:
                    token = await self._get_user_fcm_token(user_id)
                    if token:
                        fcm_tokens.append(token)
            
            if not fcm_tokens:
                return {
                    'success': False,
                    'error': 'No FCM tokens found for users',
                    'message': 'Failed to send multicast social notification'
                }
            
            # Prepare social data
            social_data = data or {}
            social_data.update({
                'type': notification_type,
                'click_action': 'FLUTTER_NOTIFICATION_CLICK'
            })
            
            # Send FCM multicast notification using the FCM service
            from services.fcm_service import FCMService
            result = FCMService.send_multicast_notification(
                tokens=fcm_tokens,
                title=title,
                body=message,
                data=social_data,
                image_url=social_data.get('image_url')
            )
            
            if result['success']:
                logger.info(f"Multicast social notification sent: {result.get('success_count')}/{len(fcm_tokens)} successful")
                return {
                    'success': True,
                    'success_count': result.get('success_count'),
                    'failure_count': result.get('failure_count'),
                    'message': f"Multicast social notification sent to {result.get('success_count')}/{len(fcm_tokens)} users"
                }
            else:
                logger.error(f"Failed to send multicast social notification: {result.get('error')}")
                return {
                    'success': False,
                    'error': result.get('error'),
                    'message': 'Failed to send multicast social notification'
                }
                
        except Exception as e:
            logger.error(f"Failed to send multicast social notification: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'message': 'Failed to send multicast social notification'
            }
    
    async def _ensure_fcm_initialized(self) -> bool:
        """Ensure FCM service is initialized"""
        if not self._fcm_initialized:
            from services.fcm_service import FCMService
            from core.config import settings
            
            if FCMService.initialize(
                project_id=settings.FCM_PROJECT_ID,
                private_key=settings.FCM_PRIVATE_KEY,
                client_email=settings.FCM_CLIENT_EMAIL
            ):
                self._fcm_initialized = True
                logger.info("FCM service initialized for notifications")
            else:
                logger.error("Failed to initialize FCM service")
                return False
        return True

# backend/alert_service/services/fcm_service.py
import logging
from typing import Dict, Any, Optional, List
from firebase_admin import credentials, initialize_app, messaging
from firebase_admin.exceptions import FirebaseError
import os

logger = logging.getLogger(__name__)# python's logging module

class FCMService:
    """Firebase Cloud Messaging service using V1 API"""
    
    _app = None
    _initialized = False
    
    @classmethod # class method is a method that is bound to the class and not the instance of the class
    def initialize(cls, project_id: str, private_key: str, client_email: str) -> bool:
        """Initialize Firebase Admin SDK with service account credentials"""
        try:
            if cls._initialized:
                logger.info("FCM service already initialized")
                return True
                
            # Create credentials from service account info
            cred = credentials.Certificate({
                "type": "service_account",
                "project_id": project_id,
                "private_key": private_key.replace('\\n', '\n'),
                "client_email": client_email,
                "token_uri": "https://oauth2.googleapis.com/token"
            })
            
            # Initialize the app
            cls._app = initialize_app(cred, name='alert-service')
            cls._initialized = True
            logger.info("FCM service initialized successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to initialize FCM service: {str(e)}")
            return False
    
    @classmethod
    def is_initialized(cls) -> bool:
        """Check if FCM service is initialized"""
        return cls._initialized and cls._app is not None
    
    @classmethod
    def send_notification(
        cls,
        token: str,
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None,
        image_url: Optional[str] = None
    ) -> Dict[str, Any]:
        """Send a single notification to a device token"""
        try:
            if not cls.is_initialized():
                return {
                    'success': False,
                    'error': 'FCM service not initialized'
                }
            
            # Create notification
            notification = messaging.Notification(
                title=title,
                body=body,
                image=image_url
            )
            
            # Create message
            message = messaging.Message(
                notification=notification,
                data=data or {},
                token=token
            )
            
            # Send message
            response = messaging.send(message, app=cls._app)
            
            logger.info(f"FCM notification sent successfully: {response}")
            return {
                'success': True,
                'message_id': response,
                'response': {'message_id': response}
            }
            
        except FirebaseError as e:
            error_msg = f"Firebase error: {str(e)}"
            logger.error(error_msg)
            return {
                'success': False,
                'error': error_msg
            }
        except Exception as e:
            error_msg = f"Unexpected error: {str(e)}"
            logger.error(error_msg)
            return {
                'success': False,
                'error': error_msg
            }
    
    @classmethod
    def send_multicast_notification(
        cls,
        tokens: List[str],
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None,
        image_url: Optional[str] = None
    ) -> Dict[str, Any]:
        """Send notification to multiple device tokens"""
        try:
            if not cls.is_initialized():
                return {
                    'success': False,
                    'error': 'FCM service not initialized'
                }
            
            if not tokens:
                return {
                    'success': False,
                    'error': 'No tokens provided'
                }
            
            # Create notification
            notification = messaging.Notification(
                title=title,
                body=body,
                image=image_url
            )
            
            # Create message
            message = messaging.MulticastMessage(
                notification=notification,
                data=data or {},
                tokens=tokens
            )
            
            # Send message (prefer multicast; if backend returns 404 on /batch, fallback to per-token sends)
            try:
                response = messaging.send_multicast(message, app=cls._app)
                logger.info(f"FCM multicast notification sent: {response.success_count}/{len(tokens)} successful")
                return {
                    'success': True,
                    'success_count': response.success_count,
                    'failure_count': response.failure_count,
                    'responses': [
                        {
                            'token': tokens[i],
                            'success': response.responses[i].success,
                            'message_id': getattr(response.responses[i], 'message_id', None),
                            'error': str(getattr(response.responses[i], 'exception', '')) if not response.responses[i].success else None
                        }
                        for i in range(len(response.responses))
                    ]
                }
            except FirebaseError as e:
                # Some environments return 404 on Google batch endpoint. Fallback to individual sends.
                logger.error(f"Multicast failed, falling back to per-token sends: {e}")
                success_count = 0
                failure_count = 0
                per_responses: List[Dict[str, Any]] = []
                for t in tokens:
                    try:
                        single_msg = messaging.Message(
                            notification=notification,
                            data=data or {},
                            token=t
                        )
                        message_id = messaging.send(single_msg, app=cls._app)
                        success_count += 1
                        per_responses.append({'token': t, 'success': True, 'message_id': message_id, 'error': None})
                    except Exception as ex:
                        failure_count += 1
                        per_responses.append({'token': t, 'success': False, 'message_id': None, 'error': str(ex)})
                return {
                    'success': success_count > 0,
                    'success_count': success_count,
                    'failure_count': failure_count,
                    'responses': per_responses
                }
            
        except FirebaseError as e:
            error_msg = f"Firebase error: {str(e)}"
            logger.error(error_msg)
            return {
                'success': False,
                'error': error_msg
            }
        except Exception as e:
            error_msg = f"Unexpected error: {str(e)}"
            logger.error(error_msg)
            return {
                'success': False,
                'error': error_msg
            }
    
    @classmethod
    def send_topic_notification(
        cls,
        topic: str,
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None,
        image_url: Optional[str] = None
    ) -> Dict[str, Any]:
        """Send notification to a topic"""
        try:
            if not cls.is_initialized():
                return {
                    'success': False,
                    'error': 'FCM service not initialized'
                }
            
            # Create notification
            notification = messaging.Notification(
                title=title,
                body=body,
                image=image_url
            )
            
            # Create message
            message = messaging.Message(
                notification=notification,
                data=data or {},
                topic=topic
            )
            
            # Send message
            response = messaging.send(message, app=cls._app)
            
            logger.info(f"FCM topic notification sent successfully: {response}")
            return {
                'success': True,
                'message_id': response,
                'response': {'message_id': response}
            }
            
        except FirebaseError as e:
            error_msg = f"Firebase error: {str(e)}"
            logger.error(error_msg)
            return {
                'success': False,
                'error': error_msg
            }
        except Exception as e:
            error_msg = f"Unexpected error: {str(e)}"
            logger.error(error_msg)
            return {
                'success': False,
                'error': error_msg
            }
    
    @classmethod
    def subscribe_to_topic(cls, tokens: List[str], topic: str) -> Dict[str, Any]:
        """Subscribe tokens to a topic"""
        try:
            if not cls.is_initialized():
                return {
                    'success': False,
                    'error': 'FCM service not initialized'
                }
            resp = messaging.subscribe_to_topic(tokens, topic, app=cls._app)
            # resp.errors is a list of TopicManagementError with .index and .reason
            error_by_index = {e.index: getattr(e, 'reason', str(e)) for e in getattr(resp, 'errors', [])}
            logger.info(f"Subscribed {resp.success_count}/{len(tokens)} tokens to topic {topic}")
            return {
                'success': True,
                'success_count': resp.success_count,
                'failure_count': resp.failure_count,
                'results': [
                    {
                        'token': tokens[i],
                        'success': i not in error_by_index,
                        'error': error_by_index.get(i)
                    }
                    for i in range(len(tokens))
                ]
            }
            
        except FirebaseError as e:
            error_msg = f"Firebase error: {str(e)}"
            logger.error(error_msg)
            return {
                'success': False,
                'error': error_msg
            }
        except Exception as e:
            error_msg = f"Unexpected error: {str(e)}"
            logger.error(error_msg)
            return {
                'success': False,
                'error': error_msg
            }
    
    @classmethod
    def unsubscribe_from_topic(cls, tokens: List[str], topic: str) -> Dict[str, Any]:
        """Unsubscribe tokens from a topic"""
        try:
            if not cls.is_initialized():
                return {
                    'success': False,
                    'error': 'FCM service not initialized'
                }
            resp = messaging.unsubscribe_from_topic(tokens, topic, app=cls._app)
            error_by_index = {e.index: getattr(e, 'reason', str(e)) for e in getattr(resp, 'errors', [])}
            logger.info(f"Unsubscribed {resp.success_count}/{len(tokens)} tokens from topic {topic}")
            return {
                'success': True,
                'success_count': resp.success_count,
                'failure_count': resp.failure_count,
                'results': [
                    {
                        'token': tokens[i],
                        'success': i not in error_by_index,
                        'error': error_by_index.get(i)
                    }
                    for i in range(len(tokens))
                ]
            }
            
        except FirebaseError as e:
            error_msg = f"Firebase error: {str(e)}"
            logger.error(error_msg)
            return {
                'success': False,
                'error': error_msg
            }
        except Exception as e:
            error_msg = f"Unexpected error: {str(e)}"
            logger.error(error_msg)
            return {
                'success': False,
                'error': error_msg
            }

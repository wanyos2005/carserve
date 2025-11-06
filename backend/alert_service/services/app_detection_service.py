# backend/alert_service/services/app_detection_service.py
from sqlalchemy.orm import Session
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
import logging
import httpx

class AppDetectionService:
    def __init__(self, db: Session):
        self.db = db
        self.user_service_url = "http://user-service:8001"  # Adjust based on your setup

    async def check_customer_has_app(self, customer_id: int) -> bool:
        """Check if customer has the app installed using multiple detection methods"""
        try:
            # Collect all detection results
            detection_results = await self._collect_all_detection_results(customer_id)
            
            # Make comprehensive decision based on all results
            return self._evaluate_app_installation(detection_results)

        except Exception as e:
            logging.getLogger("uvicorn").error(f"Error checking app installation: {e}")
            return False  # Default to no app to avoid missing opportunities

    async def _collect_all_detection_results(self, customer_id: int) -> Dict[str, Any]:
        """Collect all detection method results for comprehensive evaluation"""
        results = {}
        
        # Method 1: Check FCM token (Primary indicator)
        results['has_fcm_token'] = await self._check_fcm_token(customer_id)
        
        # Method 2: Check if user is verified (not guest)
        results['is_verified_user'] = await self._check_user_verification(customer_id)
        
        # Method 3: Check for recent app download prompts (indicates NO app)
        results['recent_prompt_sent'] = await self._check_recent_prompts(customer_id)
        
        # Method 4: Check user engagement patterns
        results['user_engagement'] = await self._check_user_engagement(customer_id)
        
        return results

    def _evaluate_app_installation(self, results: Dict[str, Any]) -> bool:
        """Evaluate app installation based on all collected results"""
        
        # Primary indicators (strong evidence of app installation)
        if results.get('has_fcm_token', False):
            logging.getLogger("uvicorn").info("FCM token found - user has app")
            return True
            
        if results.get('is_verified_user', False):
            logging.getLogger("uvicorn").info("Verified user - likely has app")
            return True
        
        # Negative indicators (evidence against app installation)
        if results.get('recent_prompt_sent', False):
            logging.getLogger("uvicorn").info("Recent prompt sent - user likely doesn't have app")
            return False
            
        # Engagement patterns
        if results.get('user_engagement', False):
            logging.getLogger("uvicorn").info("High engagement - likely has app")
            return True
            
        # Default to no app if no clear indicators
        logging.getLogger("uvicorn").info("No clear indicators - assuming no app")
        return False

    async def _check_user_engagement(self, customer_id: int) -> bool:
        """Check user engagement patterns that might indicate app usage"""
        try:
            # Check for recent activity patterns
            # This could include login frequency, feature usage, etc.
            # For now, return False as a placeholder
            return False
        except Exception as e:
            logging.getLogger("uvicorn").error(f"Error checking user engagement: {e}")
            return False

    async def _check_fcm_token(self, customer_id: int) -> bool:
        """Check if customer has FCM token (Primary app detection method)"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(f"{self.user_service_url}/users/{customer_id}")
                if response.status_code == 200:
                    user_data = response.json()
                    # Check if user has FCM token (indicates app installation)
                    fcm_token = user_data.get('fcm_token')
                    return fcm_token is not None and fcm_token.strip() != ""
                return False
        except Exception as e:
            logging.getLogger("uvicorn").error(f"Error checking FCM token: {e}")
            return False

    async def _check_user_verification(self, customer_id: int) -> bool:
        """Check if user is verified (not a guest user)"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(f"{self.user_service_url}/users/{customer_id}")
                if response.status_code == 200:
                    user_data = response.json()
                    # Check if user is verified and not a guest
                    is_verified = user_data.get('verified', False)
                    is_guest = user_data.get('is_guest', True)
                    return is_verified and not is_guest
                return False
        except Exception as e:
            logging.getLogger("uvicorn").error(f"Error checking user verification: {e}")
            return False

    async def _check_recent_prompts(self, customer_id: int) -> bool:
        """Check if app download prompt was sent recently"""
        from models.alert import Alert, AlertType
        from datetime import datetime, timedelta
        
        # Check if prompt was sent in last 30 days
        thirty_days_ago = datetime.utcnow() - timedelta(days=30)
        
        recent_prompt = self.db.query(Alert).filter(
            Alert.user_id == customer_id,
            Alert.type == AlertType.APP_DOWNLOAD_PROMPT,
            Alert.created_at >= thirty_days_ago
        ).first()
        
        return recent_prompt is not None

    async def should_send_app_prompt(self, customer_id: int) -> bool:
        """Check if we should send app download prompt (comprehensive evaluation)"""
        logger = logging.getLogger("uvicorn")
        try:
            logger.info(f"Checking app download prompt eligibility for user {customer_id}")
            
            # Collect all detection results for comprehensive evaluation
            detection_results = await self._collect_all_detection_results(customer_id)
            logger.info(f"Detection results for user {customer_id}: {detection_results}")
            
            # Check rate limiting first
            if detection_results.get('recent_prompt_sent', False):
                logger.info(f"Prompt already sent to user {customer_id} within 30 days - skipping")
                return False
            
            # Check if customer has app using comprehensive evaluation
            has_app = self._evaluate_app_installation(detection_results)
            if has_app:
                logger.info(f"User {customer_id} already has app installed - skipping prompt")
                return False
            
            # Additional checks for prompt eligibility
            is_guest = await self._check_is_guest_user(customer_id)
            logger.info(f"User {customer_id} is_guest check result: {is_guest}")
            if not is_guest:
                logger.info(f"User {customer_id} is not a guest user - skipping prompt")
                return False
            
            # Log the decision with all collected evidence
            self._log_detection_decision(customer_id, detection_results, has_app)
            
            logger.info(f"✅ App download prompt WILL BE SENT for user {customer_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error checking prompt eligibility for user {customer_id}: {e}", exc_info=True)
            return False

    def _log_detection_decision(self, customer_id: int, results: Dict[str, Any], has_app: bool):
        """Log the detection decision with all collected evidence"""
        logger = logging.getLogger("uvicorn")
        logger.info(f"App detection for user {customer_id}:")
        logger.info(f"  - FCM Token: {results.get('has_fcm_token', False)}")
        logger.info(f"  - Verified User: {results.get('is_verified_user', False)}")
        logger.info(f"  - Recent Prompt Sent: {results.get('recent_prompt_sent', False)}")
        logger.info(f"  - User Engagement: {results.get('user_engagement', False)}")
        logger.info(f"  - Final Decision: {'HAS APP' if has_app else 'NO APP'}")
        logger.info(f"  - Should Send Prompt: {'NO' if has_app else 'YES'}")

    async def _check_is_guest_user(self, customer_id: int) -> bool:
        """Check if user is a guest user (more likely to need app download prompt)"""
        logger = logging.getLogger("uvicorn")
        try:
            async with httpx.AsyncClient() as client:
                url = f"{self.user_service_url}/users/{customer_id}"
                logger.info(f"Checking if user {customer_id} is guest via {url}")
                response = await client.get(url, timeout=5.0)
                if response.status_code == 200:
                    user_data = response.json()
                    is_guest = user_data.get('is_guest', False)
                    logger.info(f"User {customer_id} data: is_guest={is_guest}, verified={user_data.get('verified')}, fcm_token={'present' if user_data.get('fcm_token') else 'missing'}")
                    return is_guest
                else:
                    logger.warning(f"User service returned {response.status_code} for user {customer_id}")
                    return False
        except Exception as e:
            logger.error(f"Error checking if user {customer_id} is guest: {e}", exc_info=True)
            return False

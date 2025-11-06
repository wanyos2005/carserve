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
            return True
            
        if results.get('is_verified_user', False):
            return True
        
        # Negative indicators (evidence against app installation)
        if results.get('recent_prompt_sent', False):
            return False
            
        # Engagement patterns
        if results.get('user_engagement', False):
            return True
            
        # Default to no app if no clear indicators
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
        logger = logging.getLogger("uvicorn")
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(f"{self.user_service_url}/users/{customer_id}", timeout=5.0)
                if response.status_code == 200:
                    user_data = response.json()
                    # Check if user has FCM token (indicates app installation)
                    fcm_token = user_data.get('fcm_token')
                    return fcm_token is not None and str(fcm_token).strip() != ""
                return False
        except Exception as e:
            logger.error(f"Error checking FCM token for user {customer_id}: {e}", exc_info=True)
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
        """Check if we should send app download prompt with priority:
        1. Guest users (highest priority)
        2. Unverified users (medium priority)
        3. Users without FCM token (lowest priority)
        """
        logger = logging.getLogger("uvicorn")
        try:
            # Collect all detection results for comprehensive evaluation
            detection_results = await self._collect_all_detection_results(customer_id)
            
            # Check rate limiting first
            if detection_results.get('recent_prompt_sent', False):
                return False
            
            # Check if customer has app using comprehensive evaluation
            has_app = self._evaluate_app_installation(detection_results)
            if has_app:
                return False
            
            # Get user details for priority-based eligibility check
            is_guest = await self._check_is_guest_user(customer_id)
            has_fcm_token = detection_results.get('has_fcm_token', False)
            is_verified = await self._get_user_verified_status(customer_id)
            
            # Safety check: If user has FCM token, they have the app - don't send prompt
            if has_fcm_token:
                return False
            
            # Priority-based eligibility: Only send to users who meet at least one priority criterion
            # Priority 1: Guest users (highest priority)
            if is_guest:
                return True
            
            # Priority 2: Unverified users (medium priority)
            if not is_verified:
                return True
            
            # Priority 3: Users without FCM token (lowest priority)
            if not has_fcm_token:
                return True
            
            # User doesn't meet any priority criteria
            return False
            
        except Exception as e:
            logger.error(f"Error checking prompt eligibility for user {customer_id}: {e}", exc_info=True)
            return False

    def _log_detection_decision(self, customer_id: int, results: Dict[str, Any], has_app: bool):
        """Log the detection decision with all collected evidence"""
        # Removed verbose logging - kept for potential future use
        pass

    async def _get_user_verified_status(self, customer_id: int) -> bool:
        """Get user's verified status directly from user service"""
        logger = logging.getLogger("uvicorn")
        try:
            async with httpx.AsyncClient() as client:
                url = f"{self.user_service_url}/users/{customer_id}"
                response = await client.get(url, timeout=5.0)
                if response.status_code == 200:
                    user_data = response.json()
                    verified_raw = user_data.get('verified')
                    verified = bool(verified_raw) if isinstance(verified_raw, bool) else (str(verified_raw).lower() in ('true', 't', '1') if verified_raw is not None else False)
                    return verified
                return False
        except Exception as e:
            logger.error(f"Error getting verified status for user {customer_id}: {e}", exc_info=True)
            return False
    
    async def _check_is_guest_user(self, customer_id: int) -> bool:
        """Check if user is a guest user (more likely to need app download prompt)"""
        logger = logging.getLogger("uvicorn")
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(f"{self.user_service_url}/users/{customer_id}", timeout=5.0)
                if response.status_code == 200:
                    user_data = response.json()
                    # Handle both boolean and string values (e.g., "true"/"false" or True/False)
                    is_guest_raw = user_data.get('is_guest', False)
                    is_guest = bool(is_guest_raw) if isinstance(is_guest_raw, bool) else str(is_guest_raw).lower() in ('true', 't', '1')
                    return is_guest
                return False
        except Exception as e:
            logger.error(f"Error checking if user {customer_id} is guest: {e}", exc_info=True)
            return False

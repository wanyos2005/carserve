#Vehicle_Service/core/security.py
# This module delegates authentication to user_service via HTTP.
# vehicle_service does NOT validate JWT tokens itself - it calls user_service.
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
import httpx
import logging

from core.config import USER_SERVICE_URL

logger = logging.getLogger(__name__)

# Adjust tokenUrl if your gateway exposes it under a different path
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="users/login")

async def get_current_user_id(token: str = Depends(oauth2_scheme)) -> str:
    """
    Get current user ID by validating token with user_service.
    vehicle_service delegates all authentication to user_service.
    No JWT secrets needed in vehicle_service!
    """
    try:
        # Call user_service to validate the token
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(
                f"{USER_SERVICE_URL}/validate-token",
                headers={"Authorization": f"Bearer {token}"}
            )
            
            if response.status_code == 200:
                user_data = response.json()
                user_id = user_data.get("user_id")
                if not user_id:
                    logger.error(f"user_service returned invalid response: {user_data}")
                    raise HTTPException(status_code=401, detail="Invalid user data from auth service")
                return str(user_id)
            elif response.status_code == 401:
                logger.warning(f"Token validation failed: {response.text}")
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid or expired token",
                    headers={"WWW-Authenticate": "Bearer"},
                )
            elif response.status_code == 404:
                logger.warning(f"User not found in user_service: {response.text}")
                raise HTTPException(status_code=404, detail="User not found")
            else:
                logger.error(f"user_service returned error: {response.status_code} - {response.text}")
                raise HTTPException(
                    status_code=502,
                    detail="Authentication service unavailable"
                )
    except httpx.TimeoutException:
        logger.error(f"Timeout calling user_service at {USER_SERVICE_URL}")
        raise HTTPException(
            status_code=503,
            detail="Authentication service timeout"
        )
    except httpx.ConnectError as e:
        logger.error(f"Cannot connect to user_service at {USER_SERVICE_URL}: {e}")
        raise HTTPException(
            status_code=503,
            detail="Authentication service unavailable"
        )
    except Exception as e:
        logger.error(f"Unexpected error validating token: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token validation failed",
            headers={"WWW-Authenticate": "Bearer"},
        )

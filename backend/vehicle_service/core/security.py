#Vehicle_Service/core/security.py
# This module handles JWT token decoding and user authentication.
# Delegates to user_service JWT validation - uses same library and secret as user_service
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError  # Use python-jose like user_service
from core.config import SECRET_KEY, ALGORITHM

# Adjust tokenUrl if your gateway exposes it under a different path
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="users/login")

def decode_access_token(token: str) -> dict:
    """
    Decode JWT token using python-jose (same library as user_service).
    Uses SECRET_KEY which matches user_service token creation.
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )

def get_current_user_id(token: str = Depends(oauth2_scheme)) -> str:
    """
    Extract user ID from JWT token (validated by user_service).
    Returns the user ID as a string from the 'sub' claim.
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        sub = payload.get("sub")
        if not sub:
            raise HTTPException(status_code=401, detail="Invalid token payload")
        return str(sub)  # Ensure it's a string
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )

def get_current_user_role(token: str = Depends(oauth2_scheme)) -> str:
    """
    Extract user role from JWT token (validated by user_service).
    Returns the role from token payload, defaulting to 'user'.
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("role", "user")
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )

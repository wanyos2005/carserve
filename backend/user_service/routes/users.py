#backend/user_service/routes/users.py
import random
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from fastapi_mail import FastMail, MessageSchema, MessageType
from jose import jwt, JWTError

from core.db import get_db
from core.security import create_access_token
from models.users import User, Roles, OTP, ProviderUserLink, User_Roles
from schemas.users import (
    SendCodeRequest,
    VerifyCodeRequest,
    LinkUserToProviderRequest,
    Token,
    EmailSchema,
    UserRead,Role, GuestUserRequest,
    FCMTokenRequest,
    FCMTokenResponse
)
from core.config import DATABASE_URL, SECRET_KEY, ALGORITHM
from mailconfig import conf

router = APIRouter()

# --------------------------
# Auth dependencies
# --------------------------
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="users/verify-code")


def generate_otp(length: int = 6) -> str:
    return "".join(str(random.randint(0, 9)) for _ in range(length))


def get_current_user(
    token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)
):
    try:
        payload = jwt.decode(
            token, SECRET_KEY, algorithms=[ALGORITHM]
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


def is_admin_user(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Dependency to check if current user is admin"""
    admin_role = db.query(Roles).filter(Roles.name == "admin").first()
    if not admin_role:
        raise HTTPException(status_code=403, detail="Admin role not configured")
    
    user_admin_role = db.query(User_Roles).filter(
        User_Roles.user_id == current_user.id,
        User_Roles.role_id == str(admin_role.id),
        User_Roles.active == True
    ).first()
    
    if not user_admin_role:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    return current_user


def send_email(email: EmailSchema, background_tasks: BackgroundTasks):
    message = MessageSchema(
        subject=email.subject,
        recipients=[email.email],
        body=email.body,
        subtype=MessageType.plain,
    )
    fm = FastMail(conf)
    background_tasks.add_task(fm.send_message, message)


# --------------------------
# Send OTP  ##create user if user does not exist
# --------------------------
@router.post("/send-code")
def send_code(
    req: SendCodeRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    # ensure user exists
    db_user = db.query(User).filter(User.email == req.email).first()
    if not db_user:
        db_user = User(email=req.email, verified=False)
        db.add(db_user)
        db.commit()
        db.refresh(db_user)

    # generate OTP
    code = generate_otp(4)
    expires_at = datetime.utcnow() + timedelta(minutes=5)

    # save OTP in DB
    otp_entry = OTP(email=req.email, code=code, expires_at=expires_at)
    db.add(otp_entry)
    db.commit()

    # send email
    send_email(
        EmailSchema(
            email=req.email,
            subject="Your Login Code",
            body=f"Your code is: {code} and expires in 5 minutes.",
        ),
        background_tasks,
    )

    return {"message": "OTP sent to email"}


# --------------------------
# Verify OTP
# --------------------------
@router.post("/verify-code", response_model=Token)
def verify_code(req: VerifyCodeRequest, db: Session = Depends(get_db)):
    otp_entry = (
        db.query(OTP)
        .filter(OTP.email == req.email, OTP.code == req.code)
        .order_by(OTP.created_at.desc())
        .first()
    )

    if not otp_entry:
        raise HTTPException(status_code=401, detail="Invalid code")

    if otp_entry.expires_at < datetime.utcnow():
        raise HTTPException(status_code=401, detail="Code expired")

    # delete OTP once used
    db.delete(otp_entry)

    # mark user as verified
    db_user = db.query(User).filter(User.email == req.email).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    db_user.verified = True

    # ✅ Link user to provider if provided and not already linked
    if req.provider_id:
        existing_link = (
            db.query(ProviderUserLink)
            .filter(
                ProviderUserLink.user_id == db_user.id,
                ProviderUserLink.provider_id == req.provider_id,
            )
            .first()
        )
        if not existing_link:
            link = ProviderUserLink(user_id=db_user.id, provider_id=req.provider_id)
            db.add(link)

    db.commit()

    # issue token
    token = create_access_token({"sub": str(db_user.id)})
    return {"access_token": token, "token_type": "bearer"}



# --------------------------
# Get current user
# --------------------------
@router.get("/me", response_model=UserRead)
def read_users_me(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Check if user is linked to any provider
    provider_link = db.query(ProviderUserLink).filter(
        ProviderUserLink.user_id == current_user.id
    ).first()

    # Check if user is admin
    admin_role = db.query(Roles).filter(Roles.name == "admin").first()
    is_admin = False
    if admin_role:
        user_admin_role = db.query(User_Roles).filter(
            User_Roles.user_id == current_user.id,
            User_Roles.role_id == str(admin_role.id),
            User_Roles.active == True
        ).first()
        is_admin = user_admin_role is not None
        print(f"DEBUG: User {current_user.email} (ID: {current_user.id}) - Admin role ID: {admin_role.id}, User admin role: {user_admin_role}, Is admin: {is_admin}")

    user_data = {
        "id": current_user.id,
        "email": current_user.email,
        "name": current_user.name,
        "phone": current_user.phone,
        "provider_id": provider_link.provider_id if provider_link else None,
        "is_admin": is_admin,
        "role": "admin" if is_admin else ("provider" if provider_link else "user")
    }

    return user_data

# --------------------------
# Minimal user lookup endpoints for other services
# --------------------------
@router.get("/users/{user_id}")
def get_user_by_id(user_id: int, db: Session = Depends(get_db)):
    """Return minimal user profile for service-to-service lookups."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return {
        "id": user.id,
        "email": user.email,
        "name": user.name,
        "phone": user.phone,
    }

@router.get("/users/{user_id}/fcm-token", response_model=FCMTokenResponse)
def get_user_fcm_token(user_id: int, db: Session = Depends(get_db)):
    """Get user's FCM token."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return FCMTokenResponse(message="FCM token retrieved", fcm_token=user.fcm_token)

@router.post("/users/{user_id}/fcm-token", response_model=FCMTokenResponse)
def register_fcm_token(
    user_id: int, 
    token_request: FCMTokenRequest,
    db: Session = Depends(get_db)
):
    """Register or update user's FCM token."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.fcm_token = token_request.fcm_token
    db.commit()
    return FCMTokenResponse(
        message="FCM token registered successfully", 
        fcm_token=token_request.fcm_token
    )

@router.delete("/users/{user_id}/fcm-token", response_model=FCMTokenResponse)
def remove_fcm_token(user_id: int, db: Session = Depends(get_db)):
    """Remove user's FCM token."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.fcm_token = None
    db.commit()
    return FCMTokenResponse(message="FCM token removed successfully")

# ---------------------------------------------------------------------------
# Nginx compatibility routes (prefix-stripped by reverse proxy)
# If the gateway location /users/ forwards and strips the prefix, user-service
# will receive paths like "/{user_id}/fcm-token". Provide aliases below.
# ---------------------------------------------------------------------------

@router.get("/{user_id}/fcm-token", response_model=FCMTokenResponse)
def get_user_fcm_token_alias(user_id: int, db: Session = Depends(get_db)):
    return get_user_fcm_token(user_id, db)

@router.post("/{user_id}/fcm-token", response_model=FCMTokenResponse)
def register_fcm_token_alias(
    user_id: int,
    token_request: FCMTokenRequest,
    db: Session = Depends(get_db)
):
    return register_fcm_token(user_id, token_request, db)

@router.delete("/{user_id}/fcm-token", response_model=FCMTokenResponse)
def remove_fcm_token_alias(user_id: int, db: Session = Depends(get_db)):
    return remove_fcm_token(user_id, db)

@router.post("/lookup")
def lookup_users_by_ids(
    user_ids: list[int],
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Look up multiple users by their IDs (authenticated users only)"""
    # This endpoint allows any authenticated user to look up user info by ID
    # This is reasonable for customer names in booking/service logs
    
    print(f"DEBUG UserService: Looking up users with IDs: {user_ids}")
    print(f"DEBUG UserService: Current user: {current_user.id} ({current_user.email})")
    
    users = db.query(User).filter(User.id.in_(user_ids)).all()
    print(f"DEBUG UserService: Found {len(users)} users in database")
    
    result = []
    for user in users:
        user_data = {
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "phone": user.phone,
        }
        result.append(user_data)
        print(f"DEBUG UserService: User {user.id}: {user_data}")
    
    print(f"DEBUG UserService: Returning {len(result)} users")
    return result

@router.get("/test-lookup/{user_id}")
def test_lookup_user(
    user_id: int,
    db: Session = Depends(get_db)
):
    """Test endpoint to check if user exists (no auth required for debugging)"""
    print(f"DEBUG UserService: Testing lookup for user ID: {user_id}")
    
    user = db.query(User).filter(User.id == user_id).first()
    if user:
        user_data = {
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "phone": user.phone,
        }
        print(f"DEBUG UserService: Found user: {user_data}")
        return user_data
    else:
        print(f"DEBUG UserService: User {user_id} not found")
        return {"error": f"User {user_id} not found"}

# --------------------------
# Get all users (Admin only)
# --------------------------
@router.get("/all", response_model=list[UserRead])
def get_all_users(current_user: User = Depends(is_admin_user), db: Session = Depends(get_db)):
    """Get all users (admin only)"""
    users = db.query(User).all()

    result = []
    for user in users:
        provider_link = db.query(ProviderUserLink).filter(
            ProviderUserLink.user_id == user.id
        ).first()

        result.append({
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "phone": user.phone,
            "provider_id": provider_link.provider_id if provider_link else None
        })

    return result

@router.get("/search", response_model=list[UserRead])
def search_users(
    q: str,
    current_user: User = Depends(is_admin_user), 
    db: Session = Depends(get_db)
):
    """Search users by email, name, or phone (admin only)"""
    if not q or len(q.strip()) < 2:
        return []
    
    search_term = f"%{q.strip()}%"
    users = db.query(User).filter(
        (User.email.ilike(search_term)) |
        (User.name.ilike(search_term)) |
        (User.phone.ilike(search_term))
    ).limit(20).all()

    result = []
    for user in users:
        provider_link = db.query(ProviderUserLink).filter(
            ProviderUserLink.user_id == user.id
        ).first()

        result.append({
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "phone": user.phone,
            "provider_id": provider_link.provider_id if provider_link else None
        })

    return result

@router.post("/link-user-provider")
def link_user_to_provider(req: LinkUserToProviderRequest, db: Session = Depends(get_db)):
    existing_link = (
        db.query(ProviderUserLink)
        .filter(
            ProviderUserLink.user_id == req.user_id,
            ProviderUserLink.provider_id == req.provider_id
        )
        .first()
    )

    if existing_link:
        raise HTTPException(status_code=400, detail="User already linked to this provider")

    link = ProviderUserLink(user_id=req.user_id, provider_id=req.provider_id)
    db.add(link)
    db.commit()
    db.refresh(link)

    return {"message": "User linked to provider successfully"}

@router.post("/guest", response_model=UserRead)
def create_or_get_guest_user(
    req: GuestUserRequest,
    db: Session = Depends(get_db),
):
    if not req.email and not req.phone:
        raise HTTPException(status_code=400, detail="Email or phone required")

    query = db.query(User)
    if req.email:
        user = query.filter(User.email == req.email).first()
    elif req.phone:
        user = query.filter(User.phone == req.phone).first()
    else:
        user = None

    if user:
        # Return properly formatted user data
        return {
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "phone": user.phone,
            "provider_id": None,  # Will be set if linked
            "is_admin": False,    # Guest users are not admins
            "role": "guest"       # Guest role
        }

    guest = User(
        email=req.email,
        phone=req.phone,
        name=req.name,
        is_guest=True,
        created_by_provider_id=req.provider_id,
        verified=False,
    )
    db.add(guest)
    db.commit()
    db.refresh(guest)
    
    # Return properly formatted guest data
    return {
        "id": guest.id,
        "email": guest.email,
        "name": guest.name,
        "phone": guest.phone,
        "provider_id": req.provider_id,  # Link to provider if provided
        "is_admin": False,               # Guest users are not admins
        "role": "guest"                  # Guest role
    }

# --------------------------
# Admin Management Endpoints
# --------------------------

@router.post("/admin/create")
def create_admin_user(
    email: str,
    name: str = None,
    current_user: User = Depends(is_admin_user),
    db: Session = Depends(get_db)
):
    """Create a new admin user (admin only)"""
    # Check if user exists
    user = db.query(User).filter(User.email == email).first()
    if not user:
        user = User(
            email=email,
            name=name or email.split('@')[0],
            verified=True
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    
    # Get admin role
    admin_role = db.query(Roles).filter(Roles.name == "admin").first()
    if not admin_role:
        raise HTTPException(status_code=500, detail="Admin role not found")
    
    # Check if user already has admin role
    existing_role = db.query(User_Roles).filter(
        User_Roles.user_id == user.id,
        User_Roles.role_id == str(admin_role.id)
    ).first()
    
    if existing_role:
        if existing_role.active:
            raise HTTPException(status_code=400, detail="User is already an admin")
        else:
            existing_role.active = True
            db.commit()
            return {"message": f"Admin privileges reactivated for {email}"}
    
    # Assign admin role
    user_role = User_Roles(
        user_id=user.id,
        role_id=str(admin_role.id),
        active=True
    )
    db.add(user_role)
    db.commit()
    
    return {"message": f"Admin privileges granted to {email}"}

@router.delete("/admin/remove")
def remove_admin_user(
    email: str,
    current_user: User = Depends(is_admin_user),
    db: Session = Depends(get_db)
):
    """Remove admin privileges from a user (admin only)"""
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    admin_role = db.query(Roles).filter(Roles.name == "admin").first()
    if not admin_role:
        raise HTTPException(status_code=500, detail="Admin role not found")
    
    user_role = db.query(User_Roles).filter(
        User_Roles.user_id == user.id,
        User_Roles.role_id == str(admin_role.id)
    ).first()
    
    if not user_role or not user_role.active:
        raise HTTPException(status_code=400, detail="User is not an admin")
    
    user_role.active = False
    db.commit()
    
    return {"message": f"Admin privileges removed from {email}"}

@router.get("/admin/list")
def list_admin_users(
    current_user: User = Depends(is_admin_user),
    db: Session = Depends(get_db)
):
    """List all admin users (admin only)"""
    admin_role = db.query(Roles).filter(Roles.name == "admin").first()
    if not admin_role:
        raise HTTPException(status_code=500, detail="Admin role not found")
    
    admin_users = db.query(User_Roles).filter(
        User_Roles.role_id == str(admin_role.id),
        User_Roles.active == True
    ).all()
    
    result = []
    for user_role in admin_users:
        user = db.query(User).filter(User.id == user_role.user_id).first()
        if user:
            result.append({
                "id": user.id,
                "email": user.email,
                "name": user.name,
                "created_at": user_role.created_at
            })
    
    return {"admins": result}

@router.get("/stats")
def get_user_stats(
    current_user: User = Depends(is_admin_user),
    db: Session = Depends(get_db)
):
    """Get user statistics (admin only)"""
    from sqlalchemy import func
    
    # Total users count
    total_users = db.query(User).count()
    
    # Verified users count (using verified field instead of is_active)
    verified_users = db.query(User).filter(User.verified == True).count()
    
    # Admin users count
    admin_role = db.query(Roles).filter(Roles.name == "admin").first()
    admin_count = 0
    if admin_role:
        admin_count = db.query(User_Roles).filter(
            User_Roles.role_id == str(admin_role.id),
            User_Roles.active == True
        ).count()
    
    # Provider users count
    provider_role = db.query(Roles).filter(Roles.name == "provider").first()
    provider_count = 0
    if provider_role:
        provider_count = db.query(User_Roles).filter(
            User_Roles.role_id == str(provider_role.id),
            User_Roles.active == True
        ).count()
    
    # Car owner users count
    car_owner_role = db.query(Roles).filter(Roles.name == "carOwner").first()
    car_owner_count = 0
    if car_owner_role:
        car_owner_count = db.query(User_Roles).filter(
            User_Roles.role_id == str(car_owner_role.id),
            User_Roles.active == True
        ).count()
    
    return {
        "total_users": total_users,
        "active_users": verified_users,  # Using verified as active
        "inactive_users": total_users - verified_users,
        "admin_users": admin_count,
        "provider_users": provider_count,
        "car_owner_users": car_owner_count
    }


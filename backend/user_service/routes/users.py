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
from models.users import User, Roles, OTP, ProviderUserLink
from schemas.users import (
    SendCodeRequest,
    VerifyCodeRequest,
    LinkUserToProviderRequest,
    Token,
    EmailSchema,
    UserRead,Role, GuestUserRequest
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

    user_data = {
        "id": current_user.id,
        "email": current_user.email,
        "name": current_user.name,
        "phone": current_user.phone,
        "provider_id": provider_link.provider_id if provider_link else None
    }

    return user_data

# --------------------------
# Get all users (Admin only)
# --------------------------
@router.get("/all", response_model=list[UserRead])
def get_all_users(db: Session = Depends(get_db)):
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
        return user

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
    return guest

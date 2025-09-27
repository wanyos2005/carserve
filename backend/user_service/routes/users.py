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
from models.users import User, OTP
from schemas.users import (
    SendCodeRequest,
    VerifyCodeRequest,
    Token,
    EmailSchema,
    UserRead,
)
from config import conf, settings  # ✅ import both

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
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
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
# Send OTP
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
    code = generate_otp(6)
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
    db.commit()

    # issue token
    token = create_access_token({"sub": str(db_user.id)})
    return {"access_token": token, "token_type": "bearer"}


# --------------------------
# Get current user
# --------------------------
@router.get("/me", response_model=UserRead)
def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user

import uuid
import random
from fastapi import FastAPI, BackgroundTasks
from fastapi_mail import FastMail, MessageSchema, MessageType
from config import conf

from fastapi import APIRouter, Depends, HTTPException 
from fastapi.security import OAuth2PasswordBearer 
from sqlalchemy.orm import Session 

from models.users import User
from schemas.users import UserCreate, UserRead, UserLogin, Token,EmailSchema
from core.db import get_db
from core.security import (
    hash_password,
    verify_password,
    create_access_token,
    decode_access_token,
)

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="users/login")

@router.post("/register", response_model=UserRead)
def register(user: UserCreate,background_tasks: BackgroundTasks,db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    pde=generate_otp(4)
    new_user = User(
        email=user.email,
        passcode=hash_password(pde),
        # role=user.role,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    email_data = EmailSchema(
        email=new_user.email,
        subject='Your OTP',
        body=pde,
    )
    send_email(email_data, background_tasks)

    return new_user

def generate_otp(length: int = 6):
    if length < 4 or length > 10:
        return {"error": "OTP length must be between 4 and 10 digits."}

    otp = ''.join([str(random.randint(0, 9)) for _ in range(length)])
    return otp

def send_email(email: EmailSchema, background_tasks: BackgroundTasks):
    message = MessageSchema(
        subject=email.subject,
        recipients=[email.email],  # List of recipients
        body=email.body,
        subtype=MessageType.html  # or MessageType.plain
    )

    fm = FastMail(conf)
    background_tasks.add_task(fm.send_message, message)
    return {"message": "email has been sent"}


@router.post("/login", response_model=Token)
def login(user: UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if not db_user or not verify_password(user.password, db_user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token({"sub": db_user.id, "role": db_user.role})
    return {"access_token": token, "token_type": "bearer"}


@router.get("/me", response_model=UserRead)
def get_me(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    try:
        payload = decode_access_token(token)
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return user

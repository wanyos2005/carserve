# models/users.py

from sqlalchemy import Column, String, TIMESTAMP, text, Integer
from core.db import Base

class User(Base):
    __tablename__ = "tbl_auth"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String, index=True)
    email = Column(String, unique=True, index=True)
    phone = Column(String, index=True)
    role = Column(String, index=True)
    passcode = Column(String)
    auth_provider = Column(String,index=True)
    verified = Column(Integer)
    created_at = Column(TIMESTAMP)
    updated_at = Column(TIMESTAMP)

from pydantic import BaseModel, EmailStr
from typing import Optional

class UserBase(BaseModel):
    email: Optional[EmailStr] = None

class SendCodeRequest(UserBase):
    pass

class VerifyCodeRequest(BaseModel):
    email: EmailStr
    code: str
    provider_id: Optional[str] = None  # ✅ NEW FIELD

class UserRead(UserBase):
    id: int
    name: Optional[str] = None
    phone: Optional[str] = None
    provider_id: Optional[str] = None  # ✅ NEW FIELD
    model_config = {"from_attributes": True}

class LinkUserToProviderRequest(BaseModel):
    user_id: int
    provider_id: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class EmailSchema(BaseModel):
    email: EmailStr
    subject: str
    body: str

class Role(BaseModel):
    name: str
    

class GuestUserRequest(BaseModel):
    email: str | None = None
    phone: str | None = None
    name: str | None = None
    provider_id: str | None = None

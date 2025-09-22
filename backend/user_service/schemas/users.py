from pydantic import BaseModel, EmailStr

class UserBase(BaseModel):
    email: EmailStr

class SendCodeRequest(UserBase):
    pass

class VerifyCodeRequest(BaseModel):
    email: EmailStr
    code: str

class UserRead(UserBase):
    id: int
    model_config = {"from_attributes": True}

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class EmailSchema(BaseModel):
    email: EmailStr
    subject: str
    body: str

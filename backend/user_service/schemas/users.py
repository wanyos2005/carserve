from pydantic import BaseModel, EmailStr

class UserBase(BaseModel):
    email: EmailStr
    # role: str = "user"

class UserCreate(UserBase):
    # passcode: str
    email: str

class UserLogin(BaseModel):
    email: EmailStr
    passcode: str

class UserRead(UserBase):
    id: int

    model_config = {
        "from_attributes": True
    }
        

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    
class EmailSchema(BaseModel):
    email: EmailStr
    subject: str
    body: str   
class EmailSchemaa(BaseModel):
    email: EmailStr
    subject: str
    body: str
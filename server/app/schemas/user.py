from pydantic import BaseModel, EmailStr


class UserOut(BaseModel):
    id: int
    email: EmailStr
    nickname: str
    language_code: str | None
    is_admin: bool
    avatar_url: str | None

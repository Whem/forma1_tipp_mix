import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_session
from app.core.config import get_settings
from app.db.models.user import User
from app.schemas.user import UserOut

router = APIRouter()


def _avatar_url(filename: str | None) -> str | None:
    if not filename:
        return None
    return f"/static/avatars/{filename}"


@router.get("/me", response_model=UserOut)
async def me(user: User = Depends(get_current_user)) -> UserOut:
    return UserOut(
        id=user.id,
        email=user.email,
        nickname=user.nickname,
        language_code=user.language_code,
        is_admin=user.is_admin,
        avatar_url=_avatar_url(user.avatar_filename),
    )


@router.post("/me/avatar", response_model=UserOut)
async def upload_avatar(
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> UserOut:
    settings = get_settings()

    suffix = Path(file.filename or "avatar").suffix.lower()
    if suffix not in {".png", ".jpg", ".jpeg", ".webp"}:
        suffix = ".png"

    filename = f"u{user.id}_{uuid.uuid4().hex}{suffix}"
    target = settings.avatars_dir / filename

    content = await file.read()
    target.write_bytes(content)

    user.avatar_filename = filename
    session.add(user)
    await session.commit()

    return UserOut(
        id=user.id,
        email=user.email,
        nickname=user.nickname,
        language_code=user.language_code,
        is_admin=user.is_admin,
        avatar_url=_avatar_url(user.avatar_filename),
    )

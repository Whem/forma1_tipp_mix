from fastapi import APIRouter

from app.api.routes import auth, live, seasons, users, votes

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(seasons.router, prefix="/seasons", tags=["seasons"])
api_router.include_router(votes.router, prefix="/votes", tags=["votes"])
api_router.include_router(live.router, prefix="/live", tags=["live"])

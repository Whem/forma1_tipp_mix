from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.router import api_router
from app.core.config import get_settings
from app.db.session import ensure_data_dirs, init_db


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(title=settings.app_name)

    allow_origins = [o.strip() for o in settings.cors_allow_origins.split(",") if o.strip()] or ["*"]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=allow_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"]
    )

    ensure_data_dirs()
    app.mount("/static", StaticFiles(directory=str(settings.data_dir)), name="static")

    app.include_router(api_router)

    @app.on_event("startup")
    async def _startup() -> None:
        await init_db()

    return app


app = create_app()

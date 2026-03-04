from collections.abc import AsyncGenerator

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import get_settings
from app.db.base import Base

_engine: AsyncEngine | None = None
_sessionmaker: async_sessionmaker[AsyncSession] | None = None


def reset_engine() -> None:
    global _engine, _sessionmaker
    _engine = None
    _sessionmaker = None


def get_engine() -> AsyncEngine:
    global _engine
    if _engine is None:
        settings = get_settings()
        _engine = create_async_engine(settings.database_url, future=True)
    return _engine


def get_sessionmaker() -> async_sessionmaker[AsyncSession]:
    global _sessionmaker
    if _sessionmaker is None:
        _sessionmaker = async_sessionmaker(get_engine(), expire_on_commit=False)
    return _sessionmaker


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async_session = get_sessionmaker()
    async with async_session() as session:
        yield session


async def init_db() -> None:
    # Import models so they register with SQLAlchemy metadata.
    from app.db import models  # noqa: F401

    engine = get_engine()
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

        if engine.dialect.name == "sqlite":
            cols = await conn.execute(text("PRAGMA table_info(vote_events)"))
            names = {row[1] for row in cols.fetchall()}
            if "race_id" not in names:
                await conn.execute(text("ALTER TABLE vote_events ADD COLUMN race_id INTEGER"))
                await conn.execute(
                    text("CREATE INDEX IF NOT EXISTS ix_vote_events_race_id ON vote_events (race_id)")
                )

            await conn.run_sync(Base.metadata.create_all)


def ensure_data_dirs() -> None:
    settings = get_settings()
    settings.data_dir.mkdir(parents=True, exist_ok=True)
    settings.avatars_dir.mkdir(parents=True, exist_ok=True)

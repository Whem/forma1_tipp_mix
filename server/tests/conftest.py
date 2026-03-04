import importlib

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient


@pytest_asyncio.fixture
async def client(tmp_path, monkeypatch) -> AsyncClient:
    db_path = tmp_path / "test.db"
    data_dir = tmp_path / "data"

    monkeypatch.setenv("DATABASE_URL", f"sqlite+aiosqlite:///{db_path}")
    monkeypatch.setenv("DATA_DIR", str(data_dir))
    monkeypatch.setenv("SECRET_KEY", "test-secret")

    from app.core.config import get_settings
    from app.core.security import hash_password
    from app.db.models.user import User
    from app.db.session import get_sessionmaker, init_db, reset_engine

    get_settings.cache_clear()
    reset_engine()

    main = importlib.import_module("app.main")
    importlib.reload(main)

    await init_db()

    async_session = get_sessionmaker()
    async with async_session() as session:
        admin = User(
            email="admin@example.com",
            password_hash=hash_password("adminpass"),
            nickname="admin",
            is_admin=True,
        )
        session.add(admin)
        await session.commit()

    transport = ASGITransport(app=main.create_app())
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

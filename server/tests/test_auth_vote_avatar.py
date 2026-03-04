from __future__ import annotations

from datetime import datetime, timedelta
from pathlib import Path

import pytest


@pytest.mark.asyncio
async def test_register_login_me_and_avatar(client):
    reg = await client.post(
        "/auth/register",
        json={"email": "u1@example.com", "password": "pass123", "nickname": "u1", "language_code": "en"},
    )
    assert reg.status_code == 200
    token = reg.json()["access_token"]

    me = await client.get("/users/me", headers={"Authorization": f"Bearer {token}"})
    assert me.status_code == 200
    assert me.json()["email"] == "u1@example.com"

    # minimal PNG header bytes; server does not validate image contents
    avatar_bytes = b"\x89PNG\r\n\x1a\n" + b"0" * 16
    up = await client.post(
        "/users/me/avatar",
        headers={"Authorization": f"Bearer {token}"},
        files={"file": ("a.png", avatar_bytes, "image/png")},
    )
    assert up.status_code == 200
    avatar_url = up.json()["avatar_url"]
    assert avatar_url and avatar_url.startswith("/static/avatars/")

    # Check file written
    from app.core.config import get_settings

    settings = get_settings()
    filename = avatar_url.split("/")[-1]
    assert (Path(settings.avatars_dir) / filename).exists()


@pytest.mark.asyncio
async def test_vote_cutoff_and_audit_chain(client):
    # admin login
    admin_login = await client.post(
        "/auth/login",
        data={"username": "admin@example.com", "password": "adminpass"},
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    assert admin_login.status_code == 200
    admin_token = admin_login.json()["access_token"]

    # create season + race far in future (voting open)
    season = await client.post(
        "/seasons/",
        json={"year": 2099},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert season.status_code == 200
    season_id = season.json()["id"]

    team = await client.post(
        f"/seasons/{season_id}/teams",
        json={"name": "Team A"},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert team.status_code == 200
    team_id = team.json()["id"]

    driver = await client.post(
        f"/seasons/{season_id}/drivers",
        json={"team_id": team_id, "name": "Driver A", "openf1_driver_number": 1},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert driver.status_code == 200
    driver_id = driver.json()["id"]

    race_start = (datetime.utcnow() + timedelta(hours=1)).replace(microsecond=0)
    race = await client.post(
        f"/seasons/{season_id}/races",
        json={"name": "Race 1", "start_time": race_start.isoformat()},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert race.status_code == 200
    race_id = race.json()["id"]

    # user register and vote
    reg = await client.post(
        "/auth/register",
        json={"email": "voter@example.com", "password": "pass123", "nickname": "voter"},
    )
    assert reg.status_code == 200
    token = reg.json()["access_token"]

    v1 = await client.post(
        "/votes/",
        json={"season_id": season_id, "vote_type": "driver_champion", "driver_id": driver_id},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert v1.status_code == 200

    v_race = await client.post(
        "/votes/",
        json={
            "season_id": season_id,
            "race_id": race_id,
            "vote_type": "race_p1",
            "driver_id": driver_id,
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    assert v_race.status_code == 200

    audit = await client.get("/votes/audit/me", headers={"Authorization": f"Bearer {token}"})
    assert audit.status_code == 200
    events = audit.json()
    assert len(events) == 2

    from app.db.models.vote import VoteEvent

    e = events[0]
    created_at = datetime.fromisoformat(e["created_at"])
    computed = VoteEvent.compute_hash(
        prev_hash=e["prev_hash"],
        user_id=0 + 1,  # can't rely on exact id here; compute via DB below
        season_id=e["season_id"],
        race_id=e["race_id"],
        vote_type=e["vote_type"],
        driver_id=e["driver_id"],
        team_id=e["team_id"],
        created_at=created_at,
    )

    # Instead of guessing user_id, validate by recomputing from DB row.
    from sqlalchemy import select

    from app.db.models.user import User
    from app.db.models.vote import VoteEvent as VoteEventModel
    from app.db.session import get_sessionmaker

    async_session = get_sessionmaker()
    async with async_session() as session:
        user_row = (await session.execute(select(User).where(User.email == "voter@example.com"))).scalar_one()
        rows = (
            await session.execute(select(VoteEventModel).where(VoteEventModel.user_id == user_row.id).order_by(VoteEventModel.id.asc()))
        ).scalars().all()

        assert len(rows) == 2
        assert rows[0].prev_hash == ""
        assert rows[1].prev_hash == rows[0].hash

        for row, event in zip(rows, events, strict=True):
            assert row.id == event["id"]
            assert row.prev_hash == event["prev_hash"]

            computed2 = VoteEvent.compute_hash(
                prev_hash=row.prev_hash,
                user_id=row.user_id,
                season_id=row.season_id,
                race_id=row.race_id,
                vote_type=row.vote_type,
                driver_id=row.driver_id,
                team_id=row.team_id,
                created_at=row.created_at,
            )

            assert row.hash == computed2
            assert event["hash"] == computed2

    assert e["hash"] == rows[0].hash

    # create season where voting is closed (race in 5 minutes -> cutoff was 5 minutes ago)
    season2 = await client.post(
        "/seasons/",
        json={"year": 2100},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert season2.status_code == 200
    s2 = season2.json()["id"]

    t2 = await client.post(
        f"/seasons/{s2}/teams",
        json={"name": "Team B"},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert t2.status_code == 200

    d2 = await client.post(
        f"/seasons/{s2}/drivers",
        json={"team_id": t2.json()["id"], "name": "Driver B"},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert d2.status_code == 200

    race_start2 = (datetime.utcnow() + timedelta(minutes=5)).replace(microsecond=0)
    race2 = await client.post(
        f"/seasons/{s2}/races",
        json={"name": "Race X", "start_time": race_start2.isoformat()},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert race2.status_code == 200

    closed = await client.post(
        "/votes/",
        json={"season_id": s2, "vote_type": "driver_champion", "driver_id": d2.json()["id"]},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert closed.status_code == 400

    race_closed = await client.post(
        "/votes/",
        json={
            "season_id": s2,
            "race_id": race2.json()["id"],
            "vote_type": "race_p1",
            "driver_id": d2.json()["id"],
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    assert race_closed.status_code == 400

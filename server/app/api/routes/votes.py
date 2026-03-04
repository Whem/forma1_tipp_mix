from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_session
from app.db.models.f1 import Race
from app.db.models.user import User
from app.db.models.vote import VoteEvent, VoteType
from app.schemas.vote import VoteCreateIn, VoteEventOut, VoteOut

router = APIRouter()


async def _season_cutoff(season_id: int, session: AsyncSession) -> tuple[bool, str]:
    result = await session.execute(
        select(Race).where(Race.season_id == season_id).order_by(Race.start_time.asc())
    )
    first_race = result.scalars().first()
    if first_race is None:
        return True, ""

    cutoff = first_race.start_time - timedelta(minutes=10)
    # Allow vote until cutoff (server timezone: naive datetime; treated consistently)
    from datetime import datetime

    if datetime.utcnow() > cutoff:
        return False, cutoff.isoformat()
    return True, cutoff.isoformat()


async def _race_cutoff(season_id: int, race_id: int, session: AsyncSession) -> tuple[bool, str]:
    result = await session.execute(select(Race).where(Race.id == race_id, Race.season_id == season_id))
    race = result.scalars().first()
    if race is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Race not found")

    cutoff = race.start_time - timedelta(minutes=10)
    if datetime.utcnow() > cutoff:
        return False, cutoff.isoformat()
    return True, cutoff.isoformat()


@router.post("/", response_model=VoteOut)
async def create_vote(
    payload: VoteCreateIn,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> VoteOut:
    valid_types = {t.value for t in VoteType}
    if payload.vote_type not in valid_types:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid vote_type")

    is_season_vote = payload.vote_type in {VoteType.DRIVER_CHAMPION.value, VoteType.TEAM_CHAMPION.value}
    is_race_vote = payload.vote_type in {VoteType.RACE_P1.value, VoteType.RACE_P2.value, VoteType.RACE_P3.value}

    if is_season_vote:
        if payload.race_id is not None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="race_id not allowed for season votes")

        ok, cutoff = await _season_cutoff(payload.season_id, session)
        if not ok:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Voting closed at {cutoff}",
            )

        if payload.vote_type == VoteType.DRIVER_CHAMPION.value and payload.driver_id is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="driver_id required")
        if payload.vote_type == VoteType.TEAM_CHAMPION.value and payload.team_id is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="team_id required")

        if payload.vote_type == VoteType.DRIVER_CHAMPION.value:
            payload.team_id = None
        if payload.vote_type == VoteType.TEAM_CHAMPION.value:
            payload.driver_id = None

    elif is_race_vote:
        if payload.race_id is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="race_id required for race votes")

        ok, cutoff = await _race_cutoff(payload.season_id, payload.race_id, session)
        if not ok:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Voting closed at {cutoff}",
            )

        if payload.driver_id is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="driver_id required")
        payload.team_id = None

    else:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid vote_type")

    last = await session.execute(
        select(VoteEvent)
        .where(VoteEvent.user_id == user.id)
        .order_by(desc(VoteEvent.id))
        .limit(1)
    )
    prev = last.scalars().first()
    prev_hash = prev.hash if prev is not None else ""

    event = VoteEvent(
        user_id=user.id,
        season_id=payload.season_id,
        race_id=payload.race_id,
        vote_type=payload.vote_type,
        driver_id=payload.driver_id,
        team_id=payload.team_id,
        created_at=datetime.utcnow(),
        prev_hash=prev_hash,
        hash="",  # computed below
    )
    event.hash = VoteEvent.compute_hash(
        prev_hash=event.prev_hash,
        user_id=event.user_id,
        season_id=event.season_id,
        race_id=event.race_id,
        vote_type=event.vote_type,
        driver_id=event.driver_id,
        team_id=event.team_id,
        created_at=event.created_at,
    )

    session.add(event)
    await session.commit()

    return VoteOut(
        season_id=event.season_id,
        race_id=event.race_id,
        vote_type=event.vote_type,
        driver_id=event.driver_id,
        team_id=event.team_id,
        created_at=event.created_at,
    )


@router.get("/season/{season_id}/my", response_model=list[VoteOut])
async def my_votes(
    season_id: int,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> list[VoteOut]:
    result = await session.execute(
        select(VoteEvent)
        .where(VoteEvent.user_id == user.id, VoteEvent.season_id == season_id)
        .order_by(VoteEvent.created_at.desc())
    )
    events = result.scalars().all()

    latest: dict[tuple[int | None, str], VoteEvent] = {}
    for e in events:
        key = (e.race_id, e.vote_type)
        if key not in latest:
            latest[key] = e

    return [
        VoteOut(
            season_id=e.season_id,
            race_id=e.race_id,
            vote_type=e.vote_type,
            driver_id=e.driver_id,
            team_id=e.team_id,
            created_at=e.created_at,
        )
        for e in latest.values()
    ]


@router.get("/audit/me", response_model=list[VoteEventOut])
async def my_audit_chain(
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> list[VoteEventOut]:
    result = await session.execute(select(VoteEvent).where(VoteEvent.user_id == user.id).order_by(VoteEvent.id.asc()))
    events = result.scalars().all()
    return [
        VoteEventOut(
            id=e.id,
            season_id=e.season_id,
            race_id=e.race_id,
            vote_type=e.vote_type,
            driver_id=e.driver_id,
            team_id=e.team_id,
            created_at=e.created_at,
            prev_hash=e.prev_hash,
            hash=e.hash,
        )
        for e in events
    ]

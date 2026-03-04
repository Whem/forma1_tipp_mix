import asyncio
import json

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_session
from app.db.models.f1 import Race
from app.services.openf1 import openf1_get

router = APIRouter()


@router.get("/sessions")
async def sessions(year: int | None = None):
    params = {"year": year} if year is not None else None
    return await openf1_get("sessions", params=params)


@router.get("/positions")
async def positions(session_key: int):
    return await openf1_get("position", params={"session_key": session_key})


@router.get("/sse/race/{race_id}/positions")
async def sse_race_positions(
    race_id: int,
    interval_ms: int = 1000,
    session: AsyncSession = Depends(get_session),
):
    if interval_ms < 250:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="interval_ms too small")

    result = await session.execute(select(Race).where(Race.id == race_id))
    race = result.scalars().first()
    if race is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Race not found")
    if race.openf1_session_key is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Race has no openf1_session_key")

    async def _gen():
        try:
            yield ": connected\n\n"
            while True:
                positions_data = await openf1_get("position", params={"session_key": race.openf1_session_key})
                payload = json.dumps({"race_id": race_id, "session_key": race.openf1_session_key, "positions": positions_data})
                yield f"event: positions\ndata: {payload}\n\n"
                await asyncio.sleep(interval_ms / 1000)
        except asyncio.CancelledError:
            return

    return StreamingResponse(
        _gen(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
        },
    )

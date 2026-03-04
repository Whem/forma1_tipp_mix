from datetime import datetime

from pydantic import BaseModel


class VoteCreateIn(BaseModel):
    season_id: int
    race_id: int | None = None
    vote_type: str
    driver_id: int | None = None
    team_id: int | None = None


class VoteOut(BaseModel):
    season_id: int
    race_id: int | None
    vote_type: str
    driver_id: int | None
    team_id: int | None
    created_at: datetime


class VoteEventOut(BaseModel):
    id: int
    season_id: int
    race_id: int | None
    vote_type: str
    driver_id: int | None
    team_id: int | None
    created_at: datetime
    prev_hash: str
    hash: str

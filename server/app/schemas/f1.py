from datetime import datetime

from pydantic import BaseModel


class SeasonCreateIn(BaseModel):
    year: int


class SeasonOut(BaseModel):
    id: int
    year: int
    is_ended: bool


class TeamCreateIn(BaseModel):
    name: str


class TeamOut(BaseModel):
    id: int
    season_id: int
    name: str


class DriverCreateIn(BaseModel):
    team_id: int
    name: str
    openf1_driver_number: int | None = None


class DriverOut(BaseModel):
    id: int
    season_id: int
    team_id: int
    name: str
    openf1_driver_number: int | None


class RaceCreateIn(BaseModel):
    name: str
    start_time: datetime
    openf1_session_key: int | None = None


class RaceOut(BaseModel):
    id: int
    season_id: int
    name: str
    start_time: datetime
    openf1_session_key: int | None

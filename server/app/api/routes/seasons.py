from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_session, require_admin
from app.db.models.f1 import Driver, Race, Season, Team
from app.schemas.f1 import DriverCreateIn, DriverOut, RaceCreateIn, RaceOut, SeasonCreateIn, SeasonOut, TeamCreateIn, TeamOut

router = APIRouter()


@router.get("/current", response_model=SeasonOut)
async def current_season(session: AsyncSession = Depends(get_session)) -> SeasonOut:
    result = await session.execute(select(Season).order_by(Season.year.desc()))
    season = result.scalars().first()
    if season is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No seasons")
    return SeasonOut(id=season.id, year=season.year, is_ended=season.is_ended)


@router.post("/", response_model=SeasonOut)
async def create_season(
    payload: SeasonCreateIn,
    session: AsyncSession = Depends(get_session),
    _admin=Depends(require_admin),
) -> SeasonOut:
    season = Season(year=payload.year, is_ended=False)
    session.add(season)
    await session.commit()
    await session.refresh(season)
    return SeasonOut(id=season.id, year=season.year, is_ended=season.is_ended)


@router.post("/{season_id}/teams", response_model=TeamOut)
async def create_team(
    season_id: int,
    payload: TeamCreateIn,
    session: AsyncSession = Depends(get_session),
    _admin=Depends(require_admin),
) -> TeamOut:
    team = Team(season_id=season_id, name=payload.name)
    session.add(team)
    await session.commit()
    await session.refresh(team)
    return TeamOut(id=team.id, season_id=team.season_id, name=team.name)


@router.get("/{season_id}/teams", response_model=list[TeamOut])
async def list_teams(season_id: int, session: AsyncSession = Depends(get_session)) -> list[TeamOut]:
    result = await session.execute(select(Team).where(Team.season_id == season_id).order_by(Team.name.asc()))
    return [TeamOut(id=t.id, season_id=t.season_id, name=t.name) for t in result.scalars().all()]


@router.post("/{season_id}/drivers", response_model=DriverOut)
async def create_driver(
    season_id: int,
    payload: DriverCreateIn,
    session: AsyncSession = Depends(get_session),
    _admin=Depends(require_admin),
) -> DriverOut:
    driver = Driver(
        season_id=season_id,
        team_id=payload.team_id,
        name=payload.name,
        openf1_driver_number=payload.openf1_driver_number,
    )
    session.add(driver)
    await session.commit()
    await session.refresh(driver)
    return DriverOut(
        id=driver.id,
        season_id=driver.season_id,
        team_id=driver.team_id,
        name=driver.name,
        openf1_driver_number=driver.openf1_driver_number,
    )


@router.get("/{season_id}/drivers", response_model=list[DriverOut])
async def list_drivers(season_id: int, session: AsyncSession = Depends(get_session)) -> list[DriverOut]:
    result = await session.execute(select(Driver).where(Driver.season_id == season_id).order_by(Driver.name.asc()))
    return [
        DriverOut(
            id=d.id,
            season_id=d.season_id,
            team_id=d.team_id,
            name=d.name,
            openf1_driver_number=d.openf1_driver_number,
        )
        for d in result.scalars().all()
    ]


@router.post("/{season_id}/races", response_model=RaceOut)
async def create_race(
    season_id: int,
    payload: RaceCreateIn,
    session: AsyncSession = Depends(get_session),
    _admin=Depends(require_admin),
) -> RaceOut:
    race = Race(
        season_id=season_id,
        name=payload.name,
        start_time=payload.start_time,
        openf1_session_key=payload.openf1_session_key,
    )
    session.add(race)
    await session.commit()
    await session.refresh(race)
    return RaceOut(
        id=race.id,
        season_id=race.season_id,
        name=race.name,
        start_time=race.start_time,
        openf1_session_key=race.openf1_session_key,
    )


@router.get("/{season_id}/races", response_model=list[RaceOut])
async def list_races(season_id: int, session: AsyncSession = Depends(get_session)) -> list[RaceOut]:
    result = await session.execute(select(Race).where(Race.season_id == season_id).order_by(Race.start_time.asc()))
    return [
        RaceOut(
            id=r.id,
            season_id=r.season_id,
            name=r.name,
            start_time=r.start_time,
            openf1_session_key=r.openf1_session_key,
        )
        for r in result.scalars().all()
    ]

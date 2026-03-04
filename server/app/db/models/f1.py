from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Season(Base):
    __tablename__ = "seasons"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    year: Mapped[int] = mapped_column(Integer, unique=True, index=True)
    is_ended: Mapped[bool] = mapped_column(default=False)


class Team(Base):
    __tablename__ = "teams"
    __table_args__ = (UniqueConstraint("season_id", "name", name="uq_team_season_name"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    season_id: Mapped[int] = mapped_column(ForeignKey("seasons.id", ondelete="CASCADE"), index=True)
    name: Mapped[str] = mapped_column(String(100))

    season: Mapped[Season] = relationship("Season")


class Driver(Base):
    __tablename__ = "drivers"
    __table_args__ = (UniqueConstraint("season_id", "name", name="uq_driver_season_name"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    season_id: Mapped[int] = mapped_column(ForeignKey("seasons.id", ondelete="CASCADE"), index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id", ondelete="CASCADE"), index=True)
    name: Mapped[str] = mapped_column(String(100))
    openf1_driver_number: Mapped[int | None] = mapped_column(Integer, nullable=True)

    season: Mapped[Season] = relationship("Season")
    team: Mapped[Team] = relationship("Team")


class Race(Base):
    __tablename__ = "races"
    __table_args__ = (UniqueConstraint("season_id", "name", name="uq_race_season_name"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    season_id: Mapped[int] = mapped_column(ForeignKey("seasons.id", ondelete="CASCADE"), index=True)
    name: Mapped[str] = mapped_column(String(120))
    start_time: Mapped[datetime] = mapped_column(DateTime, index=True)
    openf1_session_key: Mapped[int | None] = mapped_column(Integer, nullable=True)

    season: Mapped[Season] = relationship("Season")

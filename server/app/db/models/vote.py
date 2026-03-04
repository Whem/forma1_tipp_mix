from __future__ import annotations

import hashlib
from datetime import datetime
from enum import Enum

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class VoteType(str, Enum):
    DRIVER_CHAMPION = "driver_champion"
    TEAM_CHAMPION = "team_champion"
    RACE_P1 = "race_p1"
    RACE_P2 = "race_p2"
    RACE_P3 = "race_p3"


class VoteEvent(Base):
    __tablename__ = "vote_events"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    season_id: Mapped[int] = mapped_column(ForeignKey("seasons.id", ondelete="CASCADE"), index=True)

    race_id: Mapped[int | None] = mapped_column(ForeignKey("races.id", ondelete="CASCADE"), index=True, nullable=True)

    vote_type: Mapped[str] = mapped_column(String(32), index=True)

    driver_id: Mapped[int | None] = mapped_column(ForeignKey("drivers.id", ondelete="SET NULL"), nullable=True)
    team_id: Mapped[int | None] = mapped_column(ForeignKey("teams.id", ondelete="SET NULL"), nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, index=True)

    prev_hash: Mapped[str] = mapped_column(String(64), default="")
    hash: Mapped[str] = mapped_column(String(64), index=True)

    @staticmethod
    def compute_hash(
        prev_hash: str,
        user_id: int,
        season_id: int,
        race_id: int | None,
        vote_type: str,
        driver_id: int | None,
        team_id: int | None,
        created_at: datetime,
    ) -> str:
        payload = "|".join(
            [
                prev_hash or "",
                str(user_id),
                str(season_id),
                str(race_id) if race_id is not None else "",
                vote_type,
                str(driver_id) if driver_id is not None else "",
                str(team_id) if team_id is not None else "",
                created_at.replace(microsecond=0).isoformat(),
            ]
        )
        return hashlib.sha256(payload.encode("utf-8")).hexdigest()

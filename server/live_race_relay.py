import logging
import time
from datetime import datetime, timedelta

import requests
from dateutil import tz
from firebase_admin import firestore

import config

logger = logging.getLogger(__name__)
BUDAPEST = tz.gettz(config.TIMEZONE)


class LiveRaceRelay:
    def __init__(self):
        self.db = firestore.client()
        self._active = False
        self._current_race_id: str | None = None
        self._session_key: int | None = None

    def start(self):
        logger.info("LiveRaceRelay started")
        while True:
            try:
                self._tick()
            except Exception:
                logger.exception("Error in live relay tick")
            time.sleep(30)

    def _now(self) -> datetime:
        return datetime.now(BUDAPEST)

    def _tick(self):
        now = self._now()
        race = self._find_active_race(now)

        if race is None:
            if self._active:
                self._finish_relay()
            time.sleep(60)
            return

        race_id = race["id"]
        race_dt = race["datetime"]

        if not self._active:
            self._start_relay(race_id)

        self._poll_and_update(race_id, race_dt)

    def _find_active_race(self, now: datetime) -> dict | None:
        races = self.db.collection("races").order_by("raceDate").stream()

        for doc in races:
            data = doc.to_dict()
            race_dt = self._parse_race_datetime(data)
            if race_dt is None:
                continue

            window_start = race_dt - timedelta(minutes=config.RACE_WINDOW_BEFORE_MINUTES)
            window_end = race_dt + timedelta(hours=config.RACE_WINDOW_AFTER_HOURS)

            if window_start <= now <= window_end:
                return {"id": doc.id, "data": data, "datetime": race_dt}

        return None

    def _start_relay(self, race_id: str):
        self._active = True
        self._current_race_id = race_id
        self._session_key = None
        logger.info("Live relay activated for race %s", race_id)

        self.db.collection("live_races").document(race_id).set({
            "raceId": race_id,
            "status": "pre_race",
            "positions": [],
            "currentLap": 0,
            "totalLaps": 0,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        })

    def _finish_relay(self):
        if self._current_race_id:
            self.db.collection("live_races").document(self._current_race_id).update({
                "status": "finished",
                "updatedAt": firestore.SERVER_TIMESTAMP,
            })
            logger.info("Live relay finished for race %s", self._current_race_id)

        self._active = False
        self._current_race_id = None
        self._session_key = None

    def _poll_and_update(self, race_id: str, race_dt: datetime):
        if self._session_key is None:
            self._session_key = self._resolve_session_key(race_dt)
            if self._session_key is None:
                return

        positions = self._fetch_positions()
        if positions is None:
            return

        status = self._detect_status(positions)
        current_lap, total_laps = self._fetch_lap_info()

        position_list = []
        for entry in positions:
            position_list.append({
                "driverId": (entry.get("name_acronym") or "").lower(),
                "position": entry.get("position", 0),
                "gap": self._format_gap(entry),
                "pitStops": entry.get("pit_stop_count", 0),
                "retired": entry.get("status", "").upper() == "RET",
            })

        position_list.sort(key=lambda x: x["position"] if x["position"] else 999)

        update_data = {
            "raceId": race_id,
            "currentLap": current_lap,
            "totalLaps": total_laps,
            "status": status,
            "positions": position_list,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }

        self.db.collection("live_races").document(race_id).set(update_data, merge=True)
        logger.debug("Live data updated for %s: lap %d/%d, %d drivers", race_id, current_lap, total_laps, len(position_list))

        if status == "finished":
            self._finish_relay()
            return

        time.sleep(config.LIVE_POLL_INTERVAL_SECONDS)

    def _resolve_session_key(self, race_dt: datetime) -> int | None:
        try:
            resp = requests.get(
                f"{config.OPENF1_API_BASE}/sessions",
                params={
                    "session_type": "Race",
                    "year": config.SEASON,
                    "date_start>": (race_dt - timedelta(hours=2)).isoformat(),
                    "date_start<": (race_dt + timedelta(hours=2)).isoformat(),
                },
                timeout=10,
            )
            if resp.status_code == 429:
                logger.warning("OpenF1 rate limited, waiting")
                time.sleep(10)
                return None
            resp.raise_for_status()
            sessions = resp.json()
            if sessions:
                key = sessions[0].get("session_key")
                logger.info("Resolved session_key=%s for race at %s", key, race_dt)
                return key
        except requests.RequestException:
            logger.exception("Failed to resolve session key")
        return None

    def _fetch_positions(self) -> list | None:
        try:
            resp = requests.get(
                f"{config.OPENF1_API_BASE}/position",
                params={"session_key": self._session_key},
                timeout=10,
            )
            if resp.status_code == 429:
                logger.warning("OpenF1 rate limited on positions")
                time.sleep(10)
                return None
            resp.raise_for_status()
            data = resp.json()
            if not data:
                return None

            latest_by_driver: dict[int, dict] = {}
            for entry in data:
                driver_num = entry.get("driver_number")
                if driver_num is not None:
                    latest_by_driver[driver_num] = entry

            drivers_info = self._fetch_drivers()
            for driver_num, entry in latest_by_driver.items():
                info = drivers_info.get(driver_num, {})
                entry["name_acronym"] = info.get("name_acronym", "")
                entry["status"] = info.get("status", "")
                entry["pit_stop_count"] = info.get("pit_stop_count", 0)

            return list(latest_by_driver.values())
        except requests.RequestException:
            logger.exception("Failed to fetch positions")
            return None

    def _fetch_drivers(self) -> dict:
        try:
            resp = requests.get(
                f"{config.OPENF1_API_BASE}/drivers",
                params={"session_key": self._session_key},
                timeout=10,
            )
            if resp.status_code == 429:
                return {}
            resp.raise_for_status()
            return {d["driver_number"]: d for d in resp.json() if "driver_number" in d}
        except requests.RequestException:
            return {}

    def _fetch_lap_info(self) -> tuple[int, int]:
        try:
            resp = requests.get(
                f"{config.OPENF1_API_BASE}/laps",
                params={"session_key": self._session_key, "driver_number": 1},
                timeout=10,
            )
            if resp.status_code == 429 or not resp.ok:
                return 0, 0
            laps = resp.json()
            if not laps:
                return 0, 0
            current = max(l.get("lap_number", 0) for l in laps)
            return current, 0
        except (requests.RequestException, ValueError):
            return 0, 0

    def _detect_status(self, positions: list) -> str:
        if not positions:
            return "pre_race"

        statuses = [p.get("status", "").upper() for p in positions if p.get("status")]

        if any("RED" in s for s in statuses):
            return "red_flag"
        if any("SC" in s or "SAFETY" in s for s in statuses):
            return "safety_car"
        if any("VSC" in s or "VIRTUAL" in s for s in statuses):
            return "vsc"

        all_finished = all(
            p.get("status", "").upper() in ("FIN", "FINISHED", "RET", "DNF", "")
            for p in positions
        )
        has_finished = any(p.get("status", "").upper() in ("FIN", "FINISHED") for p in positions)

        if all_finished and has_finished:
            return "finished"

        if any(p.get("position", 0) > 0 for p in positions):
            return "racing"

        return "pre_race"

    @staticmethod
    def _format_gap(entry: dict) -> str:
        if entry.get("position") == 1:
            return "LEADER"
        gap = entry.get("gap_to_leader")
        if gap is not None:
            return f"+{gap}s"
        interval = entry.get("interval")
        if interval is not None:
            return f"+{interval}s"
        return ""

    @staticmethod
    def _parse_race_datetime(race: dict) -> datetime | None:
        try:
            race_date = race.get("raceDate")
            if race_date is None:
                return None
            if hasattr(race_date, 'timestamp'):
                dt = race_date.replace(tzinfo=tz.UTC) if race_date.tzinfo is None else race_date
            else:
                dt = datetime.fromisoformat(str(race_date)).replace(tzinfo=tz.UTC)
            return dt.astimezone(BUDAPEST)
        except (ValueError, TypeError):
            return None

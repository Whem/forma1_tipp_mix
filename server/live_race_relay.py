import json
import logging
import os
import time
from datetime import datetime, timedelta

import requests
from dateutil import tz
from firebase_admin import firestore

import config

logger = logging.getLogger(__name__)
BUDAPEST = tz.gettz(config.TIMEZONE)

OPENF1_TOKEN_URL = "https://api.openf1.org/token"
OPENF1_CREDS_PATH = os.path.join(config.BASE_DIR, "openf1_credentials.json")


class LiveRaceRelay:
    def __init__(self):
        self.db = firestore.client()
        self._active = False
        self._current_race_id: str | None = None
        self._session_key: int | None = None
        self._schedule: list[dict] = []
        self._openf1_token: str | None = None
        self._token_expires: datetime | None = None
        self._openf1_creds = self._load_openf1_creds()

    @staticmethod
    def _load_openf1_creds() -> dict | None:
        try:
            with open(OPENF1_CREDS_PATH) as f:
                creds = json.load(f)
                logger.info("OpenF1 credentials loaded")
                return creds
        except FileNotFoundError:
            logger.warning("OpenF1 credentials not found at %s, live data during sessions will be unavailable", OPENF1_CREDS_PATH)
            return None

    def _get_openf1_headers(self) -> dict:
        if self._openf1_creds is None:
            return {}
        now = datetime.utcnow()
        if self._openf1_token is None or self._token_expires is None or now >= self._token_expires:
            self._refresh_openf1_token()
        if self._openf1_token:
            return {"Authorization": f"Bearer {self._openf1_token}", "accept": "application/json"}
        return {}

    def _refresh_openf1_token(self):
        try:
            r = requests.post(OPENF1_TOKEN_URL, data={
                "username": self._openf1_creds["username"],
                "password": self._openf1_creds["password"],
            }, headers={"Content-Type": "application/x-www-form-urlencoded"}, timeout=10)
            if r.ok:
                data = r.json()
                self._openf1_token = data["access_token"]
                expires_in = int(data.get("expires_in", 3600))
                self._token_expires = datetime.utcnow() + timedelta(seconds=expires_in - 60)
                logger.info("OpenF1 token refreshed, expires in %ds", expires_in)
            else:
                logger.warning("Failed to get OpenF1 token: %s %s", r.status_code, r.text[:100])
        except Exception:
            logger.exception("Error refreshing OpenF1 token")

    def start(self):
        logger.info("LiveRaceRelay started")
        self._load_schedule()
        while True:
            try:
                race = self._find_active_race()
                if race is None:
                    # Fallback: check OpenF1 directly for active session
                    race = self._find_active_race_from_openf1()

                if race is None:
                    if self._active:
                        self._finish_relay()
                    sleep_sec = self._seconds_until_next_window()
                    if sleep_sec > 120:
                        logger.info("Live relay sleeping %d min until next race window", sleep_sec // 60)
                        time.sleep(min(sleep_sec, 3600))
                    else:
                        time.sleep(60)
                    continue

                if not self._active:
                    self._start_relay(race["id"])

                self._poll_and_update(race["id"], race["datetime"])
            except Exception as exc:
                err_str = str(exc).lower()
                if 'quota' in err_str or '429' in err_str or 'resource_exhausted' in err_str:
                    logger.warning("Quota exceeded, sleeping 5 min")
                    time.sleep(300)
                else:
                    logger.exception("Error in live relay tick")
                    time.sleep(30)

    def _now(self) -> datetime:
        return datetime.now(BUDAPEST)

    # ── Schedule loading ──

    def _load_schedule(self):
        try:
            logger.info("Loading race schedule from Firestore (one-time)")
            self._schedule = []
            for doc in self.db.collection("races").order_by("raceDate").stream():
                data = doc.to_dict()
                race_dt = self._parse_race_datetime(data)
                if race_dt is not None:
                    self._schedule.append({"id": doc.id, "data": data, "datetime": race_dt})
            logger.info("Loaded %d races for live relay", len(self._schedule))
        except Exception:
            logger.exception("Failed to load schedule from Firestore, will use OpenF1 fallback")

    def _find_active_race(self) -> dict | None:
        now = self._now()
        for race in self._schedule:
            race_dt = race["datetime"]
            window_start = race_dt - timedelta(minutes=config.RACE_WINDOW_BEFORE_MINUTES)
            window_end = race_dt + timedelta(hours=config.RACE_WINDOW_AFTER_HOURS)
            if window_start <= now <= window_end:
                return race
        return None

    def _find_active_race_from_openf1(self) -> dict | None:
        """Fallback: detect active race session directly from OpenF1 API."""
        headers = self._get_openf1_headers()
        try:
            r = requests.get(
                f"{config.OPENF1_API_BASE}/sessions",
                params={"session_type": "Race", "year": config.SEASON},
                headers=headers, timeout=10,
            )
            if not r.ok:
                return None
            now = self._now()
            for s in r.json():
                ds = s.get("date_start")
                if ds is None:
                    continue
                race_dt = datetime.fromisoformat(ds).astimezone(BUDAPEST)
                window_start = race_dt - timedelta(minutes=config.RACE_WINDOW_BEFORE_MINUTES)
                window_end = race_dt + timedelta(hours=config.RACE_WINDOW_AFTER_HOURS)
                if window_start <= now <= window_end:
                    session_key = s.get("session_key")
                    race_id = f"race_{session_key}"
                    logger.info("OpenF1 fallback found active race: %s (%s)", s.get("circuit_short_name"), session_key)
                    self._session_key = session_key
                    return {"id": race_id, "datetime": race_dt}
        except Exception:
            logger.exception("Failed to check OpenF1 for active session")
        return None

    def _seconds_until_next_window(self) -> float:
        now = self._now()
        soonest = float("inf")
        for race in self._schedule:
            wake = (race["datetime"] - timedelta(minutes=config.RACE_WINDOW_BEFORE_MINUTES + 5) - now).total_seconds()
            if wake > 0:
                soonest = min(soonest, wake)
        if soonest == float("inf"):
            return 300  # If no schedule, check every 5 min (OpenF1 fallback)
        return max(soonest, 0)

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

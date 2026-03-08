"""Live race service: SSE-based real-time race data + live user standings.

Architecture:
- On race window start: cache Firestore data (drivers, teams, predictions, users) ONCE
- Poll OpenF1 API with OAuth2 for positions every N seconds
- Calculate live user scores from cached predictions vs current positions
- Expose state for SSE streaming (no Firestore writes during race)
"""

import json
import logging
import os
import threading
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

# Fallback driver map for 2026 season (number -> acronym, name, team)
DRIVER_MAP_2026 = {
    1: ("VER", "Max Verstappen", "Red Bull Racing"),
    3: ("RIC", "Daniel Ricciardo", "Racing Bulls"),
    5: ("DOO", "Jack Doohan", "Alpine"),
    6: ("HAD", "Isack Hadjar", "Racing Bulls"),
    10: ("GAS", "Pierre Gasly", "Alpine"),
    11: ("PER", "Sergio Perez", "Red Bull Racing"),
    12: ("SAI", "Carlos Sainz", "Williams"),
    14: ("ALO", "Fernando Alonso", "Aston Martin"),
    16: ("LEC", "Charles Leclerc", "Ferrari"),
    18: ("STR", "Lance Stroll", "Aston Martin"),
    23: ("ALB", "Alexander Albon", "Williams"),
    27: ("HUL", "Nico Hulkenberg", "Audi"),
    30: ("BOR", "Gabriel Bortoleto", "Audi"),
    31: ("OCO", "Esteban Ocon", "Haas"),
    41: ("BEA", "Oliver Bearman", "Haas"),
    43: ("COL", "Franco Colapinto", "Alpine"),
    44: ("HAM", "Lewis Hamilton", "Ferrari"),
    55: ("SAI", "Carlos Sainz", "Williams"),
    63: ("RUS", "George Russell", "Mercedes"),
    77: ("BOT", "Valtteri Bottas", "Mercedes"),
    81: ("PIA", "Oscar Piastri", "McLaren"),
    87: ("ANT", "Andrea Kimi Antonelli", "Mercedes"),
}


class LiveService:
    """Singleton service that manages live race state and SSE broadcasting."""

    def __init__(self):
        self.db = firestore.client()
        self._lock = threading.Lock()

        # OpenF1 auth
        self._openf1_creds = self._load_creds()
        self._token: str | None = None
        self._token_expires: datetime | None = None

        # Race state
        self._active = False
        self._race_id: str | None = None
        self._session_key: int | None = None
        self._race_dt: datetime | None = None

        # Cached Firestore data (loaded once at race start)
        self._drivers: dict = {}       # driver_number -> {id, name, acronym, teamId, teamName, teamColor}
        self._predictions: list = []   # [{uid, displayName, p1, p2, p3, pole, fastestLap, joker}]
        self._users: dict = {}         # uid -> {displayName, avatarUrl}

        # Live state (updated every poll)
        self._positions: list = []     # [{position, driverNumber, acronym, name, team, gap, pitStops, retired}]
        self._current_lap: int = 0
        self._total_laps: int = 0
        self._status: str = "waiting"  # waiting, pre_race, racing, safety_car, red_flag, vsc, finished
        self._user_scores: list = []   # [{uid, displayName, avatarUrl, livePoints, details}]
        self._last_update: str = ""

        # SSE subscribers
        self._subscribers: list = []   # list of queue objects

    # ── OpenF1 Auth ──

    @staticmethod
    def _load_creds() -> dict | None:
        try:
            with open(OPENF1_CREDS_PATH) as f:
                return json.load(f)
        except FileNotFoundError:
            logger.warning("OpenF1 credentials not found")
            return None

    def _get_headers(self) -> dict:
        if not self._openf1_creds:
            return {}
        now = datetime.utcnow()
        if not self._token or not self._token_expires or now >= self._token_expires:
            self._refresh_token()
        if self._token:
            return {"Authorization": f"Bearer {self._token}", "accept": "application/json"}
        return {}

    def _refresh_token(self):
        try:
            r = requests.post(OPENF1_TOKEN_URL, data={
                "username": self._openf1_creds["username"],
                "password": self._openf1_creds["password"],
            }, headers={"Content-Type": "application/x-www-form-urlencoded"}, timeout=10)
            if r.ok:
                data = r.json()
                self._token = data["access_token"]
                expires_in = int(data.get("expires_in", 3600))
                self._token_expires = datetime.utcnow() + timedelta(seconds=expires_in - 60)
                logger.info("OpenF1 token refreshed, expires in %ds", expires_in)
            else:
                logger.warning("OpenF1 token error: %s", r.status_code)
        except Exception:
            logger.exception("OpenF1 token refresh failed")

    # ── Main Loop ──

    def start(self):
        logger.info("LiveService started")
        while True:
            try:
                if not self._active:
                    race = self._detect_active_race()
                    if race:
                        self._activate_race(race)
                    else:
                        time.sleep(60)
                        continue

                self._poll_and_broadcast()
                time.sleep(config.LIVE_POLL_INTERVAL_SECONDS)

            except Exception as exc:
                err = str(exc).lower()
                if 'quota' in err or '429' in err:
                    logger.warning("Quota issue, backing off 5 min")
                    time.sleep(300)
                else:
                    logger.exception("LiveService error")
                    time.sleep(30)

    def _detect_active_race(self) -> dict | None:
        """Check OpenF1 for currently active race session."""
        headers = self._get_headers()
        try:
            r = requests.get(
                f"{config.OPENF1_API_BASE}/sessions",
                params={"session_type": "Race", "year": config.SEASON},
                headers=headers, timeout=10,
            )
            if not r.ok:
                return None
            now = datetime.now(BUDAPEST)
            for s in r.json():
                ds = s.get("date_start")
                if not ds:
                    continue
                race_dt = datetime.fromisoformat(ds).astimezone(BUDAPEST)
                window_start = race_dt - timedelta(minutes=config.RACE_WINDOW_BEFORE_MINUTES)
                window_end = race_dt + timedelta(hours=config.RACE_WINDOW_AFTER_HOURS)
                if window_start <= now <= window_end:
                    return {
                        "session_key": s["session_key"],
                        "circuit": s.get("circuit_short_name", ""),
                        "datetime": race_dt,
                    }
        except Exception:
            logger.exception("Failed detecting active race")
        return None

    def _activate_race(self, race: dict):
        """Cache Firestore data and start live tracking."""
        self._session_key = race["session_key"]
        self._race_dt = race["datetime"]
        self._race_id = f"race_{self._session_key}"
        self._status = "pre_race"
        self._active = True

        logger.info("Activating live race: %s (session %s)", race.get("circuit", "?"), self._session_key)

        # Cache Firestore data in a background thread with timeout (don't block polling)
        cache_thread = threading.Thread(target=self._try_cache_firestore, daemon=True)
        cache_thread.start()
        cache_thread.join(timeout=15)
        if cache_thread.is_alive():
            logger.warning("Firestore cache timed out (quota?), continuing without predictions")

        logger.info("Live race activated with %d predictions cached", len(self._predictions))

    def _try_cache_firestore(self):
        try:
            self._cache_firestore_data()
        except Exception:
            logger.exception("Failed to cache Firestore data, continuing without predictions")

    def _cache_firestore_data(self):
        """Load drivers, teams, users, and predictions from Firestore ONCE."""
        db = self.db

        # Drivers
        self._drivers = {}
        for doc in db.collection("drivers").stream():
            d = doc.to_dict()
            self._drivers[doc.id] = {
                "id": doc.id,
                "firstName": d.get("firstName", ""),
                "lastName": d.get("lastName", ""),
                "acronym": d.get("acronym", doc.id.upper()[:3]),
                "number": d.get("number", 0),
                "teamId": d.get("teamId", ""),
            }

        # Teams
        teams = {}
        for doc in db.collection("teams").stream():
            d = doc.to_dict()
            teams[doc.id] = d.get("name", doc.id)

        # Enrich drivers with team name
        for drv in self._drivers.values():
            drv["teamName"] = teams.get(drv["teamId"], "")

        # Users
        self._users = {}
        for doc in db.collection("users").stream():
            d = doc.to_dict()
            self._users[doc.id] = {
                "displayName": d.get("displayName", "Unknown"),
                "avatarUrl": d.get("avatarUrl", ""),
            }

        # Find the matching Firestore race ID for predictions
        firestore_race_id = self._find_firestore_race_id()

        # Predictions for this race
        self._predictions = []
        if firestore_race_id:
            for doc in db.collection("race_predictions").where("raceId", "==", firestore_race_id).stream():
                d = doc.to_dict()
                uid = d.get("uid", "")
                user = self._users.get(uid, {})
                self._predictions.append({
                    "uid": uid,
                    "displayName": user.get("displayName", "Unknown"),
                    "avatarUrl": user.get("avatarUrl", ""),
                    "p1": d.get("p1", ""),
                    "p2": d.get("p2", ""),
                    "p3": d.get("p3", ""),
                    "pole": d.get("pole", ""),
                    "fastestLap": d.get("fastestLap", ""),
                    "joker": d.get("joker", False),
                })

        logger.info("Cached: %d drivers, %d teams, %d users, %d predictions",
                     len(self._drivers), len(teams), len(self._users), len(self._predictions))

    def _find_firestore_race_id(self) -> str | None:
        """Match OpenF1 session to Firestore race doc by date proximity."""
        try:
            if not self._race_dt:
                return None
            for doc in self.db.collection("races").stream():
                d = doc.to_dict()
                rd = d.get("raceDate")
                if rd is None:
                    continue
                if hasattr(rd, 'timestamp'):
                    dt = rd.replace(tzinfo=tz.UTC) if rd.tzinfo is None else rd
                else:
                    dt = datetime.fromisoformat(str(rd)).replace(tzinfo=tz.UTC)
                dt = dt.astimezone(BUDAPEST)
                if abs((dt - self._race_dt).total_seconds()) < 7200:  # within 2 hours
                    logger.info("Matched Firestore race: %s (%s)", doc.id, d.get("raceName", ""))
                    return doc.id
        except Exception:
            logger.exception("Failed to find Firestore race ID")
        return None

    # ── Polling & Score Calculation ──

    def _poll_and_broadcast(self):
        """Poll OpenF1, calculate scores, broadcast to SSE clients."""
        headers = self._get_headers()

        # Fetch positions
        positions = self._fetch_positions(headers)
        if positions is None:
            return

        # Fetch intervals for gap data
        intervals = self._fetch_intervals(headers)

        # Build position list using hardcoded driver map + OpenF1 data
        new_positions = []
        for entry in positions:
            num = entry.get("driver_number", 0)
            fallback = DRIVER_MAP_2026.get(num, ("???", f"Driver #{num}", ""))
            gap_data = intervals.get(num, {})

            new_positions.append({
                "position": entry.get("position", 0),
                "driverNumber": num,
                "driverId": fallback[0].lower(),
                "acronym": fallback[0],
                "name": fallback[1],
                "team": fallback[2],
                "gap": self._format_gap_from_intervals(entry, gap_data),
                "pitStops": 0,
                "retired": False,
            })
        new_positions.sort(key=lambda x: x["position"] if x["position"] else 999)

        # Fetch lap info
        current_lap, total_laps = self._fetch_lap_info(headers)

        # Detect status
        status = "racing" if current_lap > 0 else "pre_race"

        # Calculate live user scores
        user_scores = self._calculate_live_scores(new_positions)

        # Update state
        with self._lock:
            self._positions = new_positions
            self._current_lap = current_lap
            self._total_laps = total_laps
            self._status = status
            self._user_scores = user_scores
            self._last_update = datetime.now(BUDAPEST).isoformat()

        # Broadcast to SSE clients
        self._broadcast()

        logger.debug("Live update: lap %d, %d drivers, %d user scores", current_lap, len(new_positions), len(user_scores))

    def _find_driver_by_number(self, number: int) -> dict | None:
        for drv in self._drivers.values():
            if drv.get("number") == number:
                return drv
        return None

    def _calculate_live_scores(self, positions: list) -> list:
        """Calculate live points for each user based on current race positions."""
        if not positions or not self._predictions:
            return []

        # Build current podium from positions
        podium = {}  # position -> driverId
        for p in positions:
            pos = p["position"]
            if 1 <= pos <= 3:
                podium[pos] = p["driverId"]

        current_p1 = podium.get(1, "")
        current_p2 = podium.get(2, "")
        current_p3 = podium.get(3, "")
        podium_set = {current_p1, current_p2, current_p3}

        scores = []
        for pred in self._predictions:
            points = 0
            details = []

            # P1 correct
            if pred["p1"] and pred["p1"] == current_p1:
                points += config.SCORING["p1_correct"]
                details.append({"type": "p1_correct", "pts": config.SCORING["p1_correct"]})

            # P2 correct
            if pred["p2"] and pred["p2"] == current_p2:
                points += config.SCORING["p2_correct"]
                details.append({"type": "p2_correct", "pts": config.SCORING["p2_correct"]})

            # P3 correct
            if pred["p3"] and pred["p3"] == current_p3:
                points += config.SCORING["p3_correct"]
                details.append({"type": "p3_correct", "pts": config.SCORING["p3_correct"]})

            # Driver in podium (partial credit)
            for label, pid in [("p1", pred["p1"]), ("p2", pred["p2"]), ("p3", pred["p3"])]:
                if pid and pid in podium_set and pid != podium.get({"p1": 1, "p2": 2, "p3": 3}[label], ""):
                    points += config.SCORING["driver_in_podium"]
                    details.append({"type": f"{label}_in_podium", "pts": config.SCORING["driver_in_podium"]})

            # Joker doubles points
            if pred.get("joker"):
                points *= 2
                details.append({"type": "joker", "pts": points // 2})

            scores.append({
                "uid": pred["uid"],
                "displayName": pred["displayName"],
                "avatarUrl": pred["avatarUrl"],
                "livePoints": points,
                "predictions": {
                    "p1": pred["p1"], "p2": pred["p2"], "p3": pred["p3"],
                },
                "details": details,
                "joker": pred.get("joker", False),
            })

        scores.sort(key=lambda x: x["livePoints"], reverse=True)
        return scores

    # ── SSE ──

    def get_state_json(self) -> str:
        """Get current live state as JSON for SSE event."""
        with self._lock:
            return json.dumps({
                "raceId": self._race_id,
                "status": self._status,
                "currentLap": self._current_lap,
                "totalLaps": self._total_laps,
                "positions": self._positions,
                "userScores": self._user_scores,
                "updatedAt": self._last_update,
            }, ensure_ascii=False)

    def is_active(self) -> bool:
        return self._active

    def subscribe(self, queue_obj):
        with self._lock:
            self._subscribers.append(queue_obj)

    def unsubscribe(self, queue_obj):
        with self._lock:
            if queue_obj in self._subscribers:
                self._subscribers.remove(queue_obj)

    def _broadcast(self):
        data = self.get_state_json()
        with self._lock:
            dead = []
            for q in self._subscribers:
                try:
                    q.put_nowait(data)
                except Exception:
                    dead.append(q)
            for q in dead:
                self._subscribers.remove(q)

    # ── OpenF1 API Calls ──

    def _fetch_positions(self, headers: dict) -> list | None:
        try:
            r = requests.get(
                f"{config.OPENF1_API_BASE}/position",
                params={"session_key": self._session_key},
                headers=headers, timeout=10,
            )
            if not r.ok:
                logger.warning("OpenF1 positions: %s", r.status_code)
                return None
            data = r.json()
            if not data:
                return None
            latest: dict[int, dict] = {}
            for entry in data:
                dn = entry.get("driver_number")
                if dn is not None:
                    latest[dn] = entry
            return list(latest.values())
        except Exception:
            logger.exception("Failed to fetch positions")
            return None

    def _fetch_intervals(self, headers: dict) -> dict:
        """Fetch latest interval/gap data per driver."""
        try:
            r = requests.get(
                f"{config.OPENF1_API_BASE}/intervals",
                params={"session_key": self._session_key},
                headers=headers, timeout=10,
            )
            if not r.ok:
                return {}
            latest: dict[int, dict] = {}
            for entry in r.json():
                dn = entry.get("driver_number")
                if dn is not None:
                    latest[dn] = entry
            return latest
        except Exception:
            return {}

    @staticmethod
    def _format_gap_from_intervals(pos_entry: dict, interval_entry: dict) -> str:
        if pos_entry.get("position") == 1:
            return "LEADER"
        gap = interval_entry.get("gap_to_leader")
        if gap is not None:
            if isinstance(gap, str) and "LAP" in gap:
                return gap
            return f"+{gap}s"
        interval = interval_entry.get("interval")
        if interval is not None:
            return f"+{interval}s"
        return ""

    def _fetch_lap_info(self, headers: dict) -> tuple[int, int]:
        try:
            r = requests.get(
                f"{config.OPENF1_API_BASE}/laps",
                params={"session_key": self._session_key, "driver_number": 1},
                headers=headers, timeout=10,
            )
            if not r.ok:
                return 0, 0
            laps = r.json()
            if not laps:
                return 0, 0
            current = max(l.get("lap_number", 0) for l in laps)
            return current, 0
        except Exception:
            return 0, 0

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


# Singleton instance
_instance: LiveService | None = None
_instance_lock = threading.Lock()


def get_live_service() -> LiveService:
    global _instance
    with _instance_lock:
        if _instance is None:
            _instance = LiveService()
        return _instance

import logging
import time
from datetime import datetime, timedelta

import requests
import schedule
from dateutil import tz
from firebase_admin import firestore

import config

logger = logging.getLogger(__name__)
BUDAPEST = tz.gettz(config.TIMEZONE)


class RaceResultWorker:
    def __init__(self, notification_service=None):
        self.db = firestore.client()
        self.notification_service = notification_service
        self._processed_races: set[str] = set()
        self._driver_cache: dict[str, str] = {}

    def start(self):
        logger.info("RaceResultWorker started")
        schedule.every(config.RACE_CHECK_INTERVAL_MINUTES).minutes.do(self._check_results)
        while True:
            schedule.run_pending()
            time.sleep(10)

    def _now(self) -> datetime:
        return datetime.now(BUDAPEST)

    def _check_results(self):
        try:
            self._do_check()
        except Exception:
            logger.exception("Error in result check cycle")

    def _do_check(self):
        now = self._now()
        races = self.db.collection("races").order_by("round").stream()

        for race_doc in races:
            race = race_doc.to_dict()
            race_id = race_doc.id

            if race_id in self._processed_races:
                continue
            if race.get("resultsProcessed"):
                self._processed_races.add(race_id)
                continue

            race_dt = self._parse_race_datetime(race)
            if race_dt is None:
                continue

            hours_since = (now - race_dt).total_seconds() / 3600
            if hours_since < 1.5 or hours_since > 48:
                continue

            round_num = race.get("round")
            if not round_num:
                continue

            results = self._fetch_results(round_num)
            if not results:
                continue

            logger.info("Processing results for race %s (round %s)", race_id, round_num)
            self._process_results(race_id, race, results)

    def _fetch_results(self, round_num: int) -> dict | None:
        url = f"{config.F1_API_BASE}/{config.SEASON}/{round_num}/results/"
        try:
            resp = requests.get(url, timeout=15)
            if resp.status_code == 429:
                logger.warning("Rate limited by F1 API, backing off")
                time.sleep(30)
                return None
            resp.raise_for_status()
            data = resp.json()
            race_table = data.get("MRData", {}).get("RaceTable", {}).get("Races", [])
            if not race_table:
                return None
            return race_table[0]
        except requests.RequestException:
            logger.exception("Failed to fetch results for round %s", round_num)
            return None

    def _process_results(self, race_id: str, race: dict, api_data: dict):
        results_list = api_data.get("Results", [])
        if len(results_list) < 3:
            logger.warning("Incomplete results for %s, only %d entries", race_id, len(results_list))
            return

        podium = self._extract_podium(results_list)
        pole_driver = self._find_pole(results_list)
        fastest_lap_driver = self._find_fastest_lap(results_list)
        dnfs = self._find_dnfs(results_list)

        race_result = {
            "raceId": race_id,
            "season": config.SEASON,
            "round": race.get("round"),
            "p1": podium[0],
            "p2": podium[1],
            "p3": podium[2],
            "pole": pole_driver,
            "fastestLap": fastest_lap_driver,
            "dnfs": dnfs,
            "fullResults": [
                {
                    "position": int(r.get("position", 0)),
                    "driverId": self._map_driver_id(r),
                    "driverName": f"{r['Driver']['givenName']} {r['Driver']['familyName']}",
                    "constructor": r.get("Constructor", {}).get("name", ""),
                    "status": r.get("status", ""),
                }
                for r in results_list
            ],
            "processedAt": firestore.SERVER_TIMESTAMP,
        }

        self.db.collection("race_results").document(race_id).set(race_result)
        logger.info("Race results stored for %s: P1=%s P2=%s P3=%s", race_id, podium[0], podium[1], podium[2])

        self._calculate_all_user_points(race_id, race_result)

        self.db.collection("races").document(race_id).update({"resultsProcessed": True})
        self._processed_races.add(race_id)

        if self.notification_service:
            self.notification_service.send_results_notification(race_id)

    def _extract_podium(self, results: list) -> list[str]:
        podium = ["", "", ""]
        for r in results:
            pos = int(r.get("position", 0))
            if 1 <= pos <= 3:
                podium[pos - 1] = self._map_driver_id(r)
        return podium

    def _find_pole(self, results: list) -> str:
        for r in results:
            if int(r.get("grid", 0)) == 1:
                return self._map_driver_id(r)
        return ""

    def _find_fastest_lap(self, results: list) -> str:
        for r in results:
            fl = r.get("FastestLap", {})
            if fl.get("rank") == "1":
                return self._map_driver_id(r)
        return ""

    def _find_dnfs(self, results: list) -> list[str]:
        return [
            self._map_driver_id(r)
            for r in results
            if r.get("status", "").lower() not in ("finished", "+1 lap", "+2 laps", "+3 laps")
            and "lap" not in r.get("status", "").lower()
        ]

    def _map_driver_id(self, result: dict) -> str:
        ergast_id = result.get("Driver", {}).get("driverId", "")
        if ergast_id in self._driver_cache:
            return self._driver_cache[ergast_id]

        code = result.get("Driver", {}).get("code", "").lower()
        if code:
            self._driver_cache[ergast_id] = code
            return code

        short = ergast_id[:3].lower()
        self._driver_cache[ergast_id] = short
        return short

    def _calculate_all_user_points(self, race_id: str, result: dict):
        predictions = (
            self.db.collection("race_predictions")
            .where("raceId", "==", race_id)
            .stream()
        )

        batch = self.db.batch()
        batch_count = 0

        for pred_doc in predictions:
            pred = pred_doc.to_dict()
            uid = pred.get("uid")
            if not uid:
                continue

            points = self._score_prediction(pred, result)
            total = sum(points.values())

            if pred.get("isJoker"):
                total *= 2

            batch.update(pred_doc.reference, {
                "points": total,
                "pointsBreakdown": points,
                "scored": True,
            })

            user_ref = self.db.collection("users").document(uid)
            batch.update(user_ref, {
                "totalPoints": firestore.Increment(total),
                "racePoints": firestore.Increment(total),
                "racesParticipated": firestore.Increment(1),
                f"racePointsMap.{race_id}": total,
            })

            if points.get("p1_correct", 0) > 0:
                batch.update(user_ref, {"correctP1Count": firestore.Increment(1)})

            batch_count += 1

            if batch_count >= 400:
                batch.commit()
                batch = self.db.batch()
                batch_count = 0

        if batch_count > 0:
            batch.commit()

        logger.info("Scored %d predictions for race %s", batch_count, race_id)

        self._update_streaks(race_id)
        self._check_achievements(race_id, result)

    def _score_prediction(self, pred: dict, result: dict) -> dict:
        points = {}
        actual_podium = {result["p1"], result["p2"], result["p3"]}

        if pred.get("p1") == result["p1"]:
            points["p1_correct"] = config.SCORING["p1_correct"]
        elif pred.get("p1") in actual_podium:
            points["p1_in_podium"] = config.SCORING["driver_in_podium"]

        if pred.get("p2") == result["p2"]:
            points["p2_correct"] = config.SCORING["p2_correct"]
        elif pred.get("p2") in actual_podium:
            points["p2_in_podium"] = config.SCORING["driver_in_podium"]

        if pred.get("p3") == result["p3"]:
            points["p3_correct"] = config.SCORING["p3_correct"]
        elif pred.get("p3") in actual_podium:
            points["p3_in_podium"] = config.SCORING["driver_in_podium"]

        if pred.get("pole") == result.get("pole"):
            points["pole_correct"] = config.SCORING["pole_correct"]

        if pred.get("fastestLap") == result.get("fastestLap"):
            points["fastest_lap_correct"] = config.SCORING["fastest_lap_correct"]

        return points

    def _update_streaks(self, race_id: str):
        predictions = (
            self.db.collection("race_predictions")
            .where("raceId", "==", race_id)
            .stream()
        )
        predicted_users = {pred.to_dict().get("uid") for pred in predictions}

        users = self.db.collection("users").stream()
        batch = self.db.batch()
        count = 0

        for user_doc in users:
            uid = user_doc.id
            user = user_doc.to_dict()
            current_streak = user.get("currentStreak", 0)
            best_streak = user.get("bestStreak", 0)

            if uid in predicted_users:
                new_streak = current_streak + 1
                updates = {"currentStreak": new_streak}
                if new_streak > best_streak:
                    updates["bestStreak"] = new_streak
                batch.update(user_doc.reference, updates)
            else:
                if current_streak > 0:
                    batch.update(user_doc.reference, {"currentStreak": 0})

            count += 1
            if count >= 400:
                batch.commit()
                batch = self.db.batch()
                count = 0

        if count > 0:
            batch.commit()

        logger.info("Streaks updated for race %s", race_id)

    def _check_achievements(self, race_id: str, result: dict):
        predictions = (
            self.db.collection("race_predictions")
            .where("raceId", "==", race_id)
            .where("scored", "==", True)
            .stream()
        )

        batch = self.db.batch()
        count = 0

        for pred_doc in predictions:
            pred = pred_doc.to_dict()
            uid = pred.get("uid")
            if not uid:
                continue

            user_ref = self.db.collection("users").document(uid)
            user_data = user_ref.get().to_dict() or {}
            achievements = set(user_data.get("achievementIds", []) + user_data.get("achievements", []))
            new_achievements = []

            if pred.get("p1") == result["p1"] and pred.get("p2") == result["p2"] and pred.get("p3") == result["p3"]:
                if "perfect_podium" not in achievements:
                    new_achievements.append("perfect_podium")

            total_points = user_data.get("totalPoints", 0)
            if total_points >= 100 and "points_100" not in achievements:
                new_achievements.append("points_100")
            if total_points >= 500 and "points_500" not in achievements:
                new_achievements.append("points_500")

            current_streak = user_data.get("currentStreak", 0)
            if current_streak >= 3 and "streak_3" not in achievements:
                new_achievements.append("streak_3")
            if current_streak >= 5 and "streak_5" not in achievements:
                new_achievements.append("streak_5")
            if current_streak >= 10 and "streak_10" not in achievements:
                new_achievements.append("streak_10")

            p1_count = user_data.get("correctP1Count", 0)
            if p1_count >= 1 and "correct_p1_1" not in achievements:
                new_achievements.append("correct_p1_1")
            if p1_count >= 3 and "correct_p1_3" not in achievements:
                new_achievements.append("correct_p1_3")
            if p1_count >= 5 and "correct_p1_5" not in achievements:
                new_achievements.append("correct_p1_5")

            races_participated = user_data.get("racesParticipated", 0)
            if races_participated >= 1 and "first_prediction" not in achievements:
                new_achievements.append("first_prediction")
            if races_participated >= 24 and "all_races" not in achievements:
                new_achievements.append("all_races")

            if new_achievements:
                batch.update(user_ref, {
                    "achievements": firestore.ArrayUnion(new_achievements),
                    "achievementIds": firestore.ArrayUnion(new_achievements),
                })
                logger.info("Achievements %s awarded to user %s", new_achievements, uid)

            count += 1
            if count >= 400:
                batch.commit()
                batch = self.db.batch()
                count = 0

        if count > 0:
            batch.commit()

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

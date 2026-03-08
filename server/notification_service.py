import logging
import time
from datetime import datetime, timedelta

import schedule
from dateutil import tz
from firebase_admin import firestore, messaging

import config

logger = logging.getLogger(__name__)
BUDAPEST = tz.gettz(config.TIMEZONE)


class NotificationService:
    def __init__(self):
        self.db = firestore.client()
        self._sent_reminders: set[str] = set()
        self._sent_results: set[str] = set()
        self._sent_streak: set[str] = set()
        self._cached_races: list | None = None
        self._cache_time: datetime | None = None

    def start(self):
        logger.info("NotificationService started")
        schedule.every(1).minutes.do(self._check_notifications)
        while True:
            schedule.run_pending()
            time.sleep(10)

    def _now(self) -> datetime:
        return datetime.now(BUDAPEST)

    def _refresh_race_cache(self):
        now = self._now()
        if self._cached_races is None or self._cache_time is None or (now - self._cache_time).total_seconds() > 600:
            logger.debug("Refreshing race cache for notifications")
            self._cached_races = []
            for doc in self.db.collection("races").order_by("raceDate").stream():
                data = doc.to_dict()
                data["_id"] = doc.id
                self._cached_races.append(data)
            self._cache_time = now
        return self._cached_races

    def _check_notifications(self):
        try:
            self._check_race_reminders()
            self._check_streak_reminders()
        except Exception as exc:
            err_str = str(exc).lower()
            if 'quota' in err_str or '429' in err_str:
                logger.warning("Quota exceeded in notification check, will retry later")
            else:
                logger.exception("Error in notification check cycle")

    def _check_race_reminders(self):
        now = self._now()
        races = self._refresh_race_cache()

        for race in races:
            race_id = race["_id"]
            race_dt = self._parse_race_datetime(race)
            if race_dt is None:
                continue

            minutes_until = (race_dt - now).total_seconds() / 60

            reminder_key = f"reminder_{race_id}"
            if reminder_key not in self._sent_reminders and 0 < minutes_until <= 30:
                self._send_race_reminder(race_id, race.get("raceName", "Race"))
                self._sent_reminders.add(reminder_key)

    def _check_streak_reminders(self):
        now = self._now()
        next_race = self._get_next_race()
        if next_race is None:
            return

        race_id = next_race["id"]
        race_dt = self._parse_race_datetime(next_race["data"])
        if race_dt is None:
            return

        hours_until = (race_dt - now).total_seconds() / 3600
        if not (23 < hours_until <= 25):
            return

        streak_key = f"streak_{race_id}"
        if streak_key in self._sent_streak:
            return

        users = self.db.collection("users").where("currentStreak", ">", 0).stream()
        for user_doc in users:
            user = user_doc.to_dict()
            uid = user_doc.id
            prediction_docs = list(
                self.db.collection("race_predictions")
                .where("raceId", "==", race_id)
                .where("uid", "==", uid)
                .limit(1)
                .stream()
            )
            if prediction_docs:
                continue

            token = user.get("fcmToken")
            lang = user.get("language", "en")
            if not token:
                continue

            topic_key = f"streak_reminder_{lang}" if lang in ("hu", "en") else "streak_reminder_en"
            msg_data = config.NOTIFICATION_MESSAGES.get(topic_key, config.NOTIFICATION_MESSAGES["streak_reminder_en"])

            try:
                messaging.send(messaging.Message(
                    notification=messaging.Notification(title=msg_data["title"], body=msg_data["body"]),
                    token=token,
                    data={"type": "streak_reminder", "raceId": race_id},
                ))
                logger.info("Streak reminder sent to user %s for race %s", uid, race_id)
            except messaging.UnregisteredError:
                logger.warning("Token expired for user %s, clearing", uid)
                self.db.collection("users").document(uid).update({"fcmToken": firestore.DELETE_FIELD})
            except Exception:
                logger.exception("Failed to send streak reminder to user %s", uid)

        self._sent_streak.add(streak_key)

    def _send_race_reminder(self, race_id: str, race_name: str):
        for topic in config.FCM_TOPICS_REMINDER:
            lang = "hu" if topic.endswith("_hu") else "en"
            msg_data = config.NOTIFICATION_MESSAGES[f"race_reminder_{lang}"]
            try:
                messaging.send(messaging.Message(
                    notification=messaging.Notification(title=msg_data["title"], body=msg_data["body"]),
                    topic=topic,
                    data={"type": "race_reminder", "raceId": race_id, "raceName": race_name},
                ))
                logger.info("Race reminder sent to topic %s for %s", topic, race_id)
            except Exception:
                logger.exception("Failed to send reminder to topic %s", topic)

    def send_results_notification(self, race_id: str):
        result_key = f"results_{race_id}"
        if result_key in self._sent_results:
            return

        for topic in config.FCM_TOPICS_RESULTS:
            lang = "hu" if topic.endswith("_hu") else "en"
            msg_data = config.NOTIFICATION_MESSAGES[f"results_{lang}"]
            try:
                messaging.send(messaging.Message(
                    notification=messaging.Notification(title=msg_data["title"], body=msg_data["body"]),
                    topic=topic,
                    data={"type": "results_ready", "raceId": race_id},
                ))
                logger.info("Results notification sent to topic %s for %s", topic, race_id)
            except Exception:
                logger.exception("Failed to send results notification to topic %s", topic)

        self._sent_results.add(result_key)

    def _get_next_race(self) -> dict | None:
        now = self._now()
        races = self._refresh_race_cache()
        for data in races:
            race_dt = self._parse_race_datetime(data)
            if race_dt and race_dt > now:
                return {"id": data["_id"], "data": data}
        return None

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

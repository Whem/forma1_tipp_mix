import logging
import time
from datetime import datetime, timedelta

from dateutil import tz
from firebase_admin import firestore, messaging

import config

logger = logging.getLogger(__name__)
BUDAPEST = tz.gettz(config.TIMEZONE)

# How far before the race to send the race reminder (minutes)
RACE_REMINDER_BEFORE_MIN = 30
# How far before the race to send the streak reminder (hours)
STREAK_REMINDER_BEFORE_H = 24
# How far before the next event to start active polling (hours)
WAKE_UP_MARGIN_H = 25


class NotificationService:
    def __init__(self):
        self.db = firestore.client()
        self._sent_reminders: set[str] = set()
        self._sent_results: set[str] = set()
        self._sent_streak: set[str] = set()
        self._schedule: list[dict] = []

    def start(self):
        logger.info("NotificationService started")
        self._load_schedule()
        while True:
            try:
                sleep_sec = self._seconds_until_next_event()
                if sleep_sec > 60:
                    logger.info("Notification service sleeping %d min until next event", sleep_sec // 60)
                    time.sleep(min(sleep_sec, 3600))
                    continue
                self._check_and_send()
            except Exception as exc:
                err_str = str(exc).lower()
                if 'quota' in err_str or '429' in err_str or 'resource_exhausted' in err_str:
                    logger.warning("Quota exceeded, sleeping 5 min")
                    time.sleep(300)
                else:
                    logger.exception("Error in notification cycle")
                    time.sleep(60)
            time.sleep(30)

    def _now(self) -> datetime:
        return datetime.now(BUDAPEST)

    # ── Schedule loading (1 Firestore read per startup / per day) ──

    def _load_schedule(self):
        logger.info("Loading race schedule from Firestore (one-time)")
        self._schedule = []
        for doc in self.db.collection("races").order_by("raceDate").stream():
            data = doc.to_dict()
            race_dt = self._parse_race_datetime(data)
            if race_dt is not None:
                self._schedule.append({
                    "id": doc.id,
                    "name": data.get("raceName", "Race"),
                    "datetime": race_dt,
                    "data": data,
                })
        logger.info("Loaded %d races into schedule", len(self._schedule))

    def _seconds_until_next_event(self) -> float:
        now = self._now()
        soonest = float("inf")
        for race in self._schedule:
            race_dt = race["datetime"]
            # streak reminder window: 24h before race
            streak_wake = (race_dt - timedelta(hours=WAKE_UP_MARGIN_H) - now).total_seconds()
            # race reminder window: 30 min before race
            reminder_wake = (race_dt - timedelta(minutes=RACE_REMINDER_BEFORE_MIN + 5) - now).total_seconds()

            for wake in (streak_wake, reminder_wake):
                if wake > 0:
                    soonest = min(soonest, wake)

            # If we're inside an active window, return 0
            if -timedelta(hours=4).total_seconds() < (race_dt - now).total_seconds() < timedelta(hours=WAKE_UP_MARGIN_H).total_seconds():
                return 0

        if soonest == float("inf"):
            # No future races, reload schedule once a day
            return 86400
        return max(soonest, 0)

    # ── Active checking (only called when near a race) ──

    def _check_and_send(self):
        now = self._now()
        for race in self._schedule:
            race_id = race["id"]
            race_dt = race["datetime"]
            minutes_until = (race_dt - now).total_seconds() / 60
            hours_until = minutes_until / 60

            # Race reminder: 0-30 min before race
            reminder_key = f"reminder_{race_id}"
            if reminder_key not in self._sent_reminders and 0 < minutes_until <= RACE_REMINDER_BEFORE_MIN:
                self._send_race_reminder(race_id, race["name"])
                self._sent_reminders.add(reminder_key)

            # Streak reminder: 23-25h before race
            if 23 < hours_until <= 25:
                self._send_streak_reminders(race_id)

    def _send_streak_reminders(self, race_id: str):
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

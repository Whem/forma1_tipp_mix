import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

_local_path = os.path.join(BASE_DIR, "..", "forma1mix-a6ef77bba89e.json")
_deployed_path = os.path.join(BASE_DIR, "forma1mix-a6ef77bba89e.json")
SERVICE_ACCOUNT_PATH = _deployed_path if os.path.exists(_deployed_path) else _local_path

F1_API_BASE = "https://api.jolpi.ca/ergast/f1"
OPENF1_API_BASE = "https://api.openf1.org/v1"

SEASON = 2026

FCM_TOPICS_REMINDER = ["race_reminder_hu", "race_reminder_en"]
FCM_TOPICS_RESULTS = ["results_hu", "results_en"]

TIMEZONE = "Europe/Budapest"

NOTIFICATION_MESSAGES = {
    "race_reminder_hu": {
        "title": "F1 Tipp Mix",
        "body": "A futam hamarosan kezdődik! Tippeltél már?",
    },
    "race_reminder_en": {
        "title": "F1 Tipp Mix",
        "body": "Race starting soon! Did you predict?",
    },
    "results_hu": {
        "title": "F1 Tipp Mix",
        "body": "Az eredmények megérkeztek! Nézd meg a pontjaidat!",
    },
    "results_en": {
        "title": "F1 Tipp Mix",
        "body": "Results are in! Check your points!",
    },
    "streak_reminder_hu": {
        "title": "F1 Tipp Mix",
        "body": "Ne feledd leadni a tipped, hogy megőrizd a sorozatodat!",
    },
    "streak_reminder_en": {
        "title": "F1 Tipp Mix",
        "body": "Don't forget to predict and keep your streak alive!",
    },
}

SCORING = {
    "p1_correct": 25,
    "p2_correct": 18,
    "p3_correct": 15,
    "pole_correct": 10,
    "fastest_lap_correct": 5,
    "driver_in_podium": 5,
}

RACE_CHECK_INTERVAL_MINUTES = 5
LIVE_POLL_INTERVAL_SECONDS = 12
RACE_WINDOW_BEFORE_MINUTES = 30
RACE_WINDOW_AFTER_HOURS = 3

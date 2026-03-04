import os
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timezone

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SA_KEY_PATH = os.path.join(SCRIPT_DIR, "forma1mix-a6ef77bba89e.json")

cred = credentials.Certificate(SA_KEY_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()


def batch_write(collection: str, documents: dict[str, dict], label: str):
    batch = db.batch()
    count = 0
    total = 0

    for doc_id, data in documents.items():
        ref = db.collection(collection).document(doc_id)
        batch.set(ref, data, merge=True)
        count += 1
        total += 1

        if count >= 450:
            batch.commit()
            print(f"  [{label}] Committed batch ({total}/{len(documents)})")
            batch = db.batch()
            count = 0

    if count > 0:
        batch.commit()
        print(f"  [{label}] Committed final batch ({total}/{len(documents)})")

    print(f"  [{label}] Done — {total} documents written to '{collection}'")


def ts(date_str: str) -> datetime:
    return datetime.fromisoformat(date_str).replace(tzinfo=timezone.utc)


# ─── SEASONS ──────────────────────────────────────────────────────────────────

SEASONS = {
    "2026": {
        "year": 2026,
        "isActive": True,
    }
}

# ─── TEAMS ────────────────────────────────────────────────────────────────────

TEAMS = {
    "mclaren": {
        "name": "McLaren",
        "shortName": "MCL",
        "color": "#FF8000",
        "engineSupplier": "Mercedes",
        "principal": "Andrea Stella",
        "logoUrl": None,
        "nameHu": "McLaren",
        "nameEn": "McLaren",
    },
    "mercedes": {
        "name": "Mercedes",
        "shortName": "MER",
        "color": "#27F4D2",
        "engineSupplier": "Mercedes",
        "principal": "Toto Wolff",
        "logoUrl": None,
        "nameHu": "Mercedes",
        "nameEn": "Mercedes",
    },
    "red_bull": {
        "name": "Red Bull Racing",
        "shortName": "RBR",
        "color": "#3671C6",
        "engineSupplier": "Honda RBPT",
        "principal": "Christian Horner",
        "logoUrl": None,
        "nameHu": "Red Bull Racing",
        "nameEn": "Red Bull Racing",
    },
    "ferrari": {
        "name": "Ferrari",
        "shortName": "FER",
        "color": "#E8002D",
        "engineSupplier": "Ferrari",
        "principal": "Fred Vasseur",
        "logoUrl": None,
        "nameHu": "Ferrari",
        "nameEn": "Ferrari",
    },
    "williams": {
        "name": "Williams",
        "shortName": "WIL",
        "color": "#64C4FF",
        "engineSupplier": "Mercedes",
        "principal": "James Vowles",
        "logoUrl": None,
        "nameHu": "Williams",
        "nameEn": "Williams",
    },
    "aston_martin": {
        "name": "Aston Martin",
        "shortName": "AMR",
        "color": "#229971",
        "engineSupplier": "Honda RBPT",
        "principal": "Andy Cowell",
        "logoUrl": None,
        "nameHu": "Aston Martin",
        "nameEn": "Aston Martin",
    },
    "racing_bulls": {
        "name": "Racing Bulls",
        "shortName": "RCB",
        "color": "#6692FF",
        "engineSupplier": "Honda RBPT",
        "principal": "Laurent Mekies",
        "logoUrl": None,
        "nameHu": "Racing Bulls",
        "nameEn": "Racing Bulls",
    },
    "haas": {
        "name": "Haas",
        "shortName": "HAA",
        "color": "#B6BABD",
        "engineSupplier": "Ferrari",
        "principal": "Ayao Komatsu",
        "logoUrl": None,
        "nameHu": "Haas",
        "nameEn": "Haas",
    },
    "audi": {
        "name": "Audi",
        "shortName": "AUD",
        "color": "#00E701",
        "engineSupplier": "Audi",
        "principal": "Jonathan Wheatley",
        "logoUrl": None,
        "nameHu": "Audi",
        "nameEn": "Audi",
    },
    "alpine": {
        "name": "Alpine",
        "shortName": "ALP",
        "color": "#0093CC",
        "engineSupplier": "Mercedes",
        "principal": "Oliver Oakes",
        "logoUrl": None,
        "nameHu": "Alpine",
        "nameEn": "Alpine",
    },
    "cadillac": {
        "name": "Cadillac",
        "shortName": "CAD",
        "color": "#1F1F27",
        "engineSupplier": "Ferrari",
        "principal": "Graeme Lowdon",
        "logoUrl": None,
        "nameHu": "Cadillac",
        "nameEn": "Cadillac",
    },
}

# ─── DRIVERS ──────────────────────────────────────────────────────────────────

DRIVERS = {
    "nor": {"firstName": "Lando", "lastName": "Norris", "number": 4, "teamId": "mclaren", "nationality": "British", "shortCode": "NOR", "imageUrl": None},
    "pia": {"firstName": "Oscar", "lastName": "Piastri", "number": 81, "teamId": "mclaren", "nationality": "Australian", "shortCode": "PIA", "imageUrl": None},
    "rus": {"firstName": "George", "lastName": "Russell", "number": 63, "teamId": "mercedes", "nationality": "British", "shortCode": "RUS", "imageUrl": None},
    "ant": {"firstName": "Kimi", "lastName": "Antonelli", "number": 12, "teamId": "mercedes", "nationality": "Italian", "shortCode": "ANT", "imageUrl": None},
    "ver": {"firstName": "Max", "lastName": "Verstappen", "number": 1, "teamId": "red_bull", "nationality": "Dutch", "shortCode": "VER", "imageUrl": None},
    "law": {"firstName": "Liam", "lastName": "Lawson", "number": 30, "teamId": "red_bull", "nationality": "New Zealander", "shortCode": "LAW", "imageUrl": None},
    "lec": {"firstName": "Charles", "lastName": "Leclerc", "number": 16, "teamId": "ferrari", "nationality": "Monégasque", "shortCode": "LEC", "imageUrl": None},
    "ham": {"firstName": "Lewis", "lastName": "Hamilton", "number": 44, "teamId": "ferrari", "nationality": "British", "shortCode": "HAM", "imageUrl": None},
    "sai": {"firstName": "Carlos", "lastName": "Sainz", "number": 55, "teamId": "williams", "nationality": "Spanish", "shortCode": "SAI", "imageUrl": None},
    "alb": {"firstName": "Alex", "lastName": "Albon", "number": 23, "teamId": "williams", "nationality": "Thai", "shortCode": "ALB", "imageUrl": None},
    "alo": {"firstName": "Fernando", "lastName": "Alonso", "number": 14, "teamId": "aston_martin", "nationality": "Spanish", "shortCode": "ALO", "imageUrl": None},
    "str": {"firstName": "Lance", "lastName": "Stroll", "number": 18, "teamId": "aston_martin", "nationality": "Canadian", "shortCode": "STR", "imageUrl": None},
    "tsu": {"firstName": "Yuki", "lastName": "Tsunoda", "number": 22, "teamId": "racing_bulls", "nationality": "Japanese", "shortCode": "TSU", "imageUrl": None},
    "had": {"firstName": "Isack", "lastName": "Hadjar", "number": 6, "teamId": "racing_bulls", "nationality": "French", "shortCode": "HAD", "imageUrl": None},
    "oco": {"firstName": "Esteban", "lastName": "Ocon", "number": 31, "teamId": "haas", "nationality": "French", "shortCode": "OCO", "imageUrl": None},
    "bea": {"firstName": "Oliver", "lastName": "Bearman", "number": 87, "teamId": "haas", "nationality": "British", "shortCode": "BEA", "imageUrl": None},
    "hul": {"firstName": "Nico", "lastName": "Hülkenberg", "number": 27, "teamId": "audi", "nationality": "German", "shortCode": "HUL", "imageUrl": None},
    "bor": {"firstName": "Gabriel", "lastName": "Bortoleto", "number": 5, "teamId": "audi", "nationality": "Brazilian", "shortCode": "BOR", "imageUrl": None},
    "gas": {"firstName": "Pierre", "lastName": "Gasly", "number": 10, "teamId": "alpine", "nationality": "French", "shortCode": "GAS", "imageUrl": None},
    "doo": {"firstName": "Jack", "lastName": "Doohan", "number": 7, "teamId": "alpine", "nationality": "Australian", "shortCode": "DOO", "imageUrl": None},
    "tb1": {"firstName": "TBD", "lastName": "Driver 1", "number": 99, "teamId": "cadillac", "nationality": "TBD", "shortCode": "TB1", "imageUrl": None},
    "tb2": {"firstName": "TBD", "lastName": "Driver 2", "number": 98, "teamId": "cadillac", "nationality": "TBD", "shortCode": "TB2", "imageUrl": None},
}

# ─── RACES ────────────────────────────────────────────────────────────────────

RACES = {
    "2026_r01": {"round": 1,  "nameHu": "Ausztrál Nagydíj",            "nameEn": "Australian Grand Prix",         "circuit": "Albert Park Circuit",                     "country": "Australia",            "countryCode": "AU", "flagEmoji": "🇦🇺", "raceDate": ts("2026-03-15T06:00:00"), "sprintWeekend": False},
    "2026_r02": {"round": 2,  "nameHu": "Kínai Nagydíj",               "nameEn": "Chinese Grand Prix",            "circuit": "Shanghai International Circuit",           "country": "China",                "countryCode": "CN", "flagEmoji": "🇨🇳", "raceDate": ts("2026-03-29T06:00:00"), "sprintWeekend": False},
    "2026_r03": {"round": 3,  "nameHu": "Japán Nagydíj",               "nameEn": "Japanese Grand Prix",           "circuit": "Suzuka International Racing Course",       "country": "Japan",                "countryCode": "JP", "flagEmoji": "🇯🇵", "raceDate": ts("2026-04-12T06:00:00"), "sprintWeekend": False},
    "2026_r04": {"round": 4,  "nameHu": "Bahreini Nagydíj",            "nameEn": "Bahrain Grand Prix",            "circuit": "Bahrain International Circuit",            "country": "Bahrain",              "countryCode": "BH", "flagEmoji": "🇧🇭", "raceDate": ts("2026-04-19T14:00:00"), "sprintWeekend": False},
    "2026_r05": {"round": 5,  "nameHu": "Szaúd-arábiai Nagydíj",       "nameEn": "Saudi Arabian Grand Prix",      "circuit": "Jeddah Corniche Circuit",                  "country": "Saudi Arabia",         "countryCode": "SA", "flagEmoji": "🇸🇦", "raceDate": ts("2026-04-26T14:00:00"), "sprintWeekend": False},
    "2026_r06": {"round": 6,  "nameHu": "Miami Nagydíj",               "nameEn": "Miami Grand Prix",              "circuit": "Miami International Autodrome",             "country": "United States",        "countryCode": "US", "flagEmoji": "🇺🇸", "raceDate": ts("2026-05-10T19:00:00"), "sprintWeekend": True},
    "2026_r07": {"round": 7,  "nameHu": "Emilia-romagnai Nagydíj",     "nameEn": "Emilia Romagna Grand Prix",     "circuit": "Autodromo Enzo e Dino Ferrari",             "country": "Italy",                "countryCode": "IT", "flagEmoji": "🇮🇹", "raceDate": ts("2026-05-24T13:00:00"), "sprintWeekend": False},
    "2026_r08": {"round": 8,  "nameHu": "Monacói Nagydíj",             "nameEn": "Monaco Grand Prix",             "circuit": "Circuit de Monaco",                        "country": "Monaco",               "countryCode": "MC", "flagEmoji": "🇲🇨", "raceDate": ts("2026-05-31T13:00:00"), "sprintWeekend": False},
    "2026_r09": {"round": 9,  "nameHu": "Spanyol Nagydíj",             "nameEn": "Spanish Grand Prix",            "circuit": "Circuit de Barcelona-Catalunya",            "country": "Spain",                "countryCode": "ES", "flagEmoji": "🇪🇸", "raceDate": ts("2026-06-14T13:00:00"), "sprintWeekend": False},
    "2026_r10": {"round": 10, "nameHu": "Kanadai Nagydíj",             "nameEn": "Canadian Grand Prix",           "circuit": "Circuit Gilles Villeneuve",                 "country": "Canada",               "countryCode": "CA", "flagEmoji": "🇨🇦", "raceDate": ts("2026-06-28T19:00:00"), "sprintWeekend": False},
    "2026_r11": {"round": 11, "nameHu": "Osztrák Nagydíj",             "nameEn": "Austrian Grand Prix",           "circuit": "Red Bull Ring",                            "country": "Austria",              "countryCode": "AT", "flagEmoji": "🇦🇹", "raceDate": ts("2026-07-05T13:00:00"), "sprintWeekend": True},
    "2026_r12": {"round": 12, "nameHu": "Brit Nagydíj",                "nameEn": "British Grand Prix",            "circuit": "Silverstone Circuit",                      "country": "United Kingdom",       "countryCode": "GB", "flagEmoji": "🇬🇧", "raceDate": ts("2026-07-19T13:00:00"), "sprintWeekend": False},
    "2026_r13": {"round": 13, "nameHu": "Belga Nagydíj",               "nameEn": "Belgian Grand Prix",            "circuit": "Circuit de Spa-Francorchamps",              "country": "Belgium",              "countryCode": "BE", "flagEmoji": "🇧🇪", "raceDate": ts("2026-07-26T13:00:00"), "sprintWeekend": True},
    "2026_r14": {"round": 14, "nameHu": "Magyar Nagydíj",              "nameEn": "Hungarian Grand Prix",          "circuit": "Hungaroring",                              "country": "Hungary",              "countryCode": "HU", "flagEmoji": "🇭🇺", "raceDate": ts("2026-08-02T13:00:00"), "sprintWeekend": False},
    "2026_r15": {"round": 15, "nameHu": "Holland Nagydíj",             "nameEn": "Dutch Grand Prix",              "circuit": "Circuit Zandvoort",                        "country": "Netherlands",          "countryCode": "NL", "flagEmoji": "🇳🇱", "raceDate": ts("2026-08-30T13:00:00"), "sprintWeekend": False},
    "2026_r16": {"round": 16, "nameHu": "Olasz Nagydíj",               "nameEn": "Italian Grand Prix",            "circuit": "Autodromo Nazionale di Monza",              "country": "Italy",                "countryCode": "IT", "flagEmoji": "🇮🇹", "raceDate": ts("2026-09-06T13:00:00"), "sprintWeekend": False},
    "2026_r17": {"round": 17, "nameHu": "Azerbajdzsáni Nagydíj",       "nameEn": "Azerbaijan Grand Prix",         "circuit": "Baku City Circuit",                        "country": "Azerbaijan",           "countryCode": "AZ", "flagEmoji": "🇦🇿", "raceDate": ts("2026-09-20T14:00:00"), "sprintWeekend": False},
    "2026_r18": {"round": 18, "nameHu": "Szingapúri Nagydíj",          "nameEn": "Singapore Grand Prix",          "circuit": "Marina Bay Street Circuit",                 "country": "Singapore",            "countryCode": "SG", "flagEmoji": "🇸🇬", "raceDate": ts("2026-10-04T13:00:00"), "sprintWeekend": True},
    "2026_r19": {"round": 19, "nameHu": "Egyesült Államok Nagydíja",   "nameEn": "United States Grand Prix",      "circuit": "Circuit of the Americas",                   "country": "United States",        "countryCode": "US", "flagEmoji": "🇺🇸", "raceDate": ts("2026-10-18T19:00:00"), "sprintWeekend": True},
    "2026_r20": {"round": 20, "nameHu": "Mexikói Nagydíj",             "nameEn": "Mexico City Grand Prix",        "circuit": "Autódromo Hermanos Rodríguez",              "country": "Mexico",               "countryCode": "MX", "flagEmoji": "🇲🇽", "raceDate": ts("2026-10-25T19:00:00"), "sprintWeekend": False},
    "2026_r21": {"round": 21, "nameHu": "Brazil Nagydíj",              "nameEn": "Brazilian Grand Prix",          "circuit": "Autódromo José Carlos Pace",                "country": "Brazil",               "countryCode": "BR", "flagEmoji": "🇧🇷", "raceDate": ts("2026-11-08T19:00:00"), "sprintWeekend": True},
    "2026_r22": {"round": 22, "nameHu": "Las Vegas-i Nagydíj",         "nameEn": "Las Vegas Grand Prix",          "circuit": "Las Vegas Strip Circuit",                   "country": "United States",        "countryCode": "US", "flagEmoji": "🇺🇸", "raceDate": ts("2026-11-22T19:00:00"), "sprintWeekend": False},
    "2026_r23": {"round": 23, "nameHu": "Katari Nagydíj",              "nameEn": "Qatar Grand Prix",              "circuit": "Lusail International Circuit",              "country": "Qatar",                "countryCode": "QA", "flagEmoji": "🇶🇦", "raceDate": ts("2026-11-29T14:00:00"), "sprintWeekend": False},
    "2026_r24": {"round": 24, "nameHu": "Abu-dzabi Nagydíj",           "nameEn": "Abu Dhabi Grand Prix",          "circuit": "Yas Marina Circuit",                       "country": "United Arab Emirates", "countryCode": "AE", "flagEmoji": "🇦🇪", "raceDate": ts("2026-12-06T14:00:00"), "sprintWeekend": False},
}

# ─── ACHIEVEMENTS ─────────────────────────────────────────────────────────────

ACHIEVEMENTS = {
    "first_prediction": {
        "nameHu": "Első tipp",
        "nameEn": "First Prediction",
        "descriptionHu": "Add le az első futam tipped",
        "descriptionEn": "Submit your first race prediction",
        "icon": "sports_score",
        "threshold": 1,
        "type": "participation",
    },
    "streak_3": {
        "nameHu": "Sorozatban 3",
        "nameEn": "Hot Streak",
        "descriptionHu": "Tippelj 3 egymást követő futamra",
        "descriptionEn": "Predict 3 races in a row",
        "icon": "local_fire_department",
        "threshold": 3,
        "type": "streak",
    },
    "streak_5": {
        "nameHu": "Lángokban",
        "nameEn": "On Fire",
        "descriptionHu": "Tippelj 5 egymást követő futamra",
        "descriptionEn": "Predict 5 races in a row",
        "icon": "whatshot",
        "threshold": 5,
        "type": "streak",
    },
    "streak_10": {
        "nameHu": "Megállíthatatlan",
        "nameEn": "Unstoppable",
        "descriptionHu": "Tippelj 10 egymást követő futamra",
        "descriptionEn": "Predict 10 races in a row",
        "icon": "bolt",
        "threshold": 10,
        "type": "streak",
    },
    "correct_p1_1": {
        "nameHu": "Jövendőmondó",
        "nameEn": "Fortune Teller",
        "descriptionHu": "Helyesen tippeld meg a futam győztesét",
        "descriptionEn": "Correctly predict the race winner",
        "icon": "emoji_events",
        "threshold": 1,
        "type": "correct_p1",
    },
    "correct_p1_3": {
        "nameHu": "Orákulum",
        "nameEn": "Oracle",
        "descriptionHu": "Helyesen tippeld meg 3 futam győztesét",
        "descriptionEn": "Correctly predict 3 race winners",
        "icon": "auto_awesome",
        "threshold": 3,
        "type": "correct_p1",
    },
    "correct_p1_5": {
        "nameHu": "Próféta",
        "nameEn": "Prophet",
        "descriptionHu": "Helyesen tippeld meg 5 futam győztesét",
        "descriptionEn": "Correctly predict 5 race winners",
        "icon": "psychology",
        "threshold": 5,
        "type": "correct_p1",
    },
    "perfect_podium": {
        "nameHu": "Dobogó Mester",
        "nameEn": "Podium Master",
        "descriptionHu": "Helyesen tippeld meg a teljes dobogót",
        "descriptionEn": "Correctly predict the full podium",
        "icon": "military_tech",
        "threshold": 1,
        "type": "perfect_podium",
    },
    "all_races": {
        "nameHu": "Vasember",
        "nameEn": "Iron Man",
        "descriptionHu": "Vegyél részt mind a 24 futamon",
        "descriptionEn": "Participate in all 24 races",
        "icon": "fitness_center",
        "threshold": 24,
        "type": "participation",
    },
    "points_100": {
        "nameHu": "Százas",
        "nameEn": "Century",
        "descriptionHu": "Érj el 100 összpontot",
        "descriptionEn": "Reach 100 total points",
        "icon": "looks_one",
        "threshold": 100,
        "type": "points",
    },
    "points_500": {
        "nameHu": "Fél ezres",
        "nameEn": "Half K",
        "descriptionHu": "Érj el 500 összpontot",
        "descriptionEn": "Reach 500 total points",
        "icon": "star",
        "threshold": 500,
        "type": "points",
    },
    "joker_win": {
        "nameHu": "Szerencsés Joker",
        "nameEn": "Lucky Joker",
        "descriptionHu": "Nyerj nagyot egy Joker futammal",
        "descriptionEn": "Win big with a Joker race",
        "icon": "casino",
        "threshold": 1,
        "type": "joker",
    },
    "season_champ": {
        "nameHu": "Látnok",
        "nameEn": "Seer",
        "descriptionHu": "Helyesen tippeld meg a világbajnokot",
        "descriptionEn": "Correctly predict the World Champion",
        "icon": "workspace_premium",
        "threshold": 1,
        "type": "season",
    },
}


def main():
    print("=" * 60)
    print("  F1 2026 Season — Firestore Seed Script")
    print("=" * 60)

    print("\n[1/5] Seeding seasons...")
    batch_write("seasons", SEASONS, "seasons")

    print("\n[2/5] Seeding teams...")
    batch_write("teams", TEAMS, "teams")

    print("\n[3/5] Seeding drivers...")
    batch_write("drivers", DRIVERS, "drivers")

    print("\n[4/5] Seeding races...")
    batch_write("races", RACES, "races")

    print("\n[5/5] Seeding achievements...")
    batch_write("achievements", ACHIEVEMENTS, "achievements")

    print("\n" + "=" * 60)
    print("  Seeding complete!")
    print(f"  Seasons:      {len(SEASONS)}")
    print(f"  Teams:        {len(TEAMS)}")
    print(f"  Drivers:      {len(DRIVERS)}")
    print(f"  Races:        {len(RACES)}")
    print(f"  Achievements: {len(ACHIEVEMENTS)}")
    print("=" * 60)


if __name__ == "__main__":
    main()

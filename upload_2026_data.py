#!/usr/bin/env python3
"""Upload complete 2026 F1 season data to Firestore."""
import sys
sys.stdout.reconfigure(encoding='utf-8')

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timezone, timedelta

cred = credentials.Certificate('h:/work/gitlab/test_server/forma1_tipp_mix/forma1mix-a6ef77bba89e.json')
app = firebase_admin.initialize_app(cred)
db = firestore.client()

# Hungarian timezone offsets
CET = timedelta(hours=1)   # UTC+1 (winter)
CEST = timedelta(hours=2)  # UTC+2 (summer)
# DST switch 2026: Mar 29 02:00 -> 03:00, Oct 25 03:00 -> 02:00

def hu_to_utc(year, month, day, hour, minute, tz_offset):
    """Convert Hungarian local time to UTC datetime."""
    local = datetime(year, month, day, hour, minute)
    return (local - tz_offset).replace(tzinfo=timezone.utc)

# Country codes & flag emojis
def flag(code):
    return ''.join(chr(0x1F1E6 + ord(c) - ord('A')) for c in code.upper())

# ============================================================
# RACES - Grand Prix times in Hungarian time
# ============================================================
races = [
    {
        'id': '2026_r01', 'round': 1,
        'nameHu': 'Ausztrál Nagydíj', 'nameEn': 'Australian Grand Prix',
        'circuit': 'Albert Park Circuit', 'country': 'Ausztrália', 'countryCode': 'AU',
        'raceDate': hu_to_utc(2026, 3, 8, 5, 0, CET),
        'sprintWeekend': False,
    },
    {
        'id': '2026_r02', 'round': 2,
        'nameHu': 'Kínai Nagydíj', 'nameEn': 'Chinese Grand Prix',
        'circuit': 'Shanghai International Circuit', 'country': 'Kína', 'countryCode': 'CN',
        'raceDate': hu_to_utc(2026, 3, 15, 8, 0, CET),
        'sprintWeekend': True,
    },
    {
        'id': '2026_r03', 'round': 3,
        'nameHu': 'Japán Nagydíj', 'nameEn': 'Japanese Grand Prix',
        'circuit': 'Suzuka International Racing Course', 'country': 'Japán', 'countryCode': 'JP',
        'raceDate': hu_to_utc(2026, 3, 29, 7, 0, CEST),  # After DST switch
        'sprintWeekend': False,
    },
    {
        'id': '2026_r04', 'round': 4,
        'nameHu': 'Bahreini Nagydíj', 'nameEn': 'Bahrain Grand Prix',
        'circuit': 'Bahrain International Circuit', 'country': 'Bahrein', 'countryCode': 'BH',
        'raceDate': hu_to_utc(2026, 4, 12, 17, 0, CEST),
        'sprintWeekend': False,
    },
    {
        'id': '2026_r05', 'round': 5,
        'nameHu': 'Szaúd-arábiai Nagydíj', 'nameEn': 'Saudi Arabian Grand Prix',
        'circuit': 'Jeddah Corniche Circuit', 'country': 'Szaúd-Arábia', 'countryCode': 'SA',
        'raceDate': hu_to_utc(2026, 4, 19, 19, 0, CEST),
        'sprintWeekend': False,
    },
    {
        'id': '2026_r06', 'round': 6,
        'nameHu': 'Miami Nagydíj', 'nameEn': 'Miami Grand Prix',
        'circuit': 'Miami International Autodrome', 'country': 'USA', 'countryCode': 'US',
        'raceDate': hu_to_utc(2026, 5, 3, 22, 0, CEST),
        'sprintWeekend': True,
    },
    {
        'id': '2026_r07', 'round': 7,
        'nameHu': 'Kanadai Nagydíj', 'nameEn': 'Canadian Grand Prix',
        'circuit': 'Circuit Gilles Villeneuve', 'country': 'Kanada', 'countryCode': 'CA',
        'raceDate': hu_to_utc(2026, 5, 24, 22, 0, CEST),
        'sprintWeekend': True,
    },
    {
        'id': '2026_r08', 'round': 8,
        'nameHu': 'Monacói Nagydíj', 'nameEn': 'Monaco Grand Prix',
        'circuit': 'Circuit de Monaco', 'country': 'Monaco', 'countryCode': 'MC',
        'raceDate': hu_to_utc(2026, 6, 7, 15, 0, CEST),
        'sprintWeekend': False,
    },
    {
        'id': '2026_r09', 'round': 9,
        'nameHu': 'Barcelona-Catalunya Nagydíj', 'nameEn': 'Barcelona-Catalunya Grand Prix',
        'circuit': 'Circuit de Barcelona-Catalunya', 'country': 'Spanyolország', 'countryCode': 'ES',
        'raceDate': hu_to_utc(2026, 6, 14, 15, 0, CEST),
        'sprintWeekend': False,
    },
    {
        'id': '2026_r10', 'round': 10,
        'nameHu': 'Osztrák Nagydíj', 'nameEn': 'Austrian Grand Prix',
        'circuit': 'Red Bull Ring', 'country': 'Ausztria', 'countryCode': 'AT',
        'raceDate': hu_to_utc(2026, 6, 28, 15, 0, CEST),
        'sprintWeekend': False,
    },
    {
        'id': '2026_r11', 'round': 11,
        'nameHu': 'Brit Nagydíj', 'nameEn': 'British Grand Prix',
        'circuit': 'Silverstone Circuit', 'country': 'Nagy-Britannia', 'countryCode': 'GB',
        'raceDate': hu_to_utc(2026, 7, 5, 16, 0, CEST),
        'sprintWeekend': True,
    },
    {
        'id': '2026_r12', 'round': 12,
        'nameHu': 'Belga Nagydíj', 'nameEn': 'Belgian Grand Prix',
        'circuit': 'Circuit de Spa-Francorchamps', 'country': 'Belgium', 'countryCode': 'BE',
        'raceDate': hu_to_utc(2026, 7, 19, 15, 0, CEST),
        'sprintWeekend': False,
    },
    {
        'id': '2026_r13', 'round': 13,
        'nameHu': 'Magyar Nagydíj', 'nameEn': 'Hungarian Grand Prix',
        'circuit': 'Hungaroring', 'country': 'Magyarország', 'countryCode': 'HU',
        'raceDate': hu_to_utc(2026, 7, 26, 15, 0, CEST),
        'sprintWeekend': False,
    },
    {
        'id': '2026_r14', 'round': 14,
        'nameHu': 'Holland Nagydíj', 'nameEn': 'Dutch Grand Prix',
        'circuit': 'Circuit Zandvoort', 'country': 'Hollandia', 'countryCode': 'NL',
        'raceDate': hu_to_utc(2026, 8, 23, 15, 0, CEST),
        'sprintWeekend': True,
    },
    {
        'id': '2026_r15', 'round': 15,
        'nameHu': 'Olasz Nagydíj', 'nameEn': 'Italian Grand Prix',
        'circuit': 'Autodromo Nazionale Monza', 'country': 'Olaszország', 'countryCode': 'IT',
        'raceDate': hu_to_utc(2026, 9, 6, 15, 0, CEST),
        'sprintWeekend': False,
    },
    {
        'id': '2026_r16', 'round': 16,
        'nameHu': 'Spanyol Nagydíj', 'nameEn': 'Spanish Grand Prix',
        'circuit': 'Madrid Street Circuit', 'country': 'Spanyolország', 'countryCode': 'ES',
        'raceDate': hu_to_utc(2026, 9, 13, 15, 0, CEST),
        'sprintWeekend': False,
    },
    {
        'id': '2026_r17', 'round': 17,
        'nameHu': 'Azeri Nagydíj', 'nameEn': 'Azerbaijan Grand Prix',
        'circuit': 'Baku City Circuit', 'country': 'Azerbajdzsán', 'countryCode': 'AZ',
        'raceDate': hu_to_utc(2026, 9, 26, 13, 0, CEST),
        'sprintWeekend': False,
    },
    {
        'id': '2026_r18', 'round': 18,
        'nameHu': 'Szingapúri Nagydíj', 'nameEn': 'Singapore Grand Prix',
        'circuit': 'Marina Bay Street Circuit', 'country': 'Szingapúr', 'countryCode': 'SG',
        'raceDate': hu_to_utc(2026, 10, 11, 14, 0, CEST),
        'sprintWeekend': True,
    },
    {
        'id': '2026_r19', 'round': 19,
        'nameHu': 'Amerikai Nagydíj', 'nameEn': 'United States Grand Prix',
        'circuit': 'Circuit of the Americas', 'country': 'USA', 'countryCode': 'US',
        'raceDate': hu_to_utc(2026, 10, 25, 21, 0, CET),  # After DST switch back
        'sprintWeekend': False,
    },
    {
        'id': '2026_r20', 'round': 20,
        'nameHu': 'Mexikóvárosi Nagydíj', 'nameEn': 'Mexico City Grand Prix',
        'circuit': 'Autódromo Hermanos Rodríguez', 'country': 'Mexikó', 'countryCode': 'MX',
        'raceDate': hu_to_utc(2026, 11, 1, 21, 0, CET),
        'sprintWeekend': False,
    },
    {
        'id': '2026_r21', 'round': 21,
        'nameHu': 'Brazil Nagydíj', 'nameEn': 'Brazilian Grand Prix',
        'circuit': 'Autódromo José Carlos Pace', 'country': 'Brazília', 'countryCode': 'BR',
        'raceDate': hu_to_utc(2026, 11, 8, 18, 0, CET),
        'sprintWeekend': False,
    },
    {
        'id': '2026_r22', 'round': 22,
        'nameHu': 'Las Vegas Nagydíj', 'nameEn': 'Las Vegas Grand Prix',
        'circuit': 'Las Vegas Strip Circuit', 'country': 'USA', 'countryCode': 'US',
        'raceDate': hu_to_utc(2026, 11, 22, 5, 0, CET),
        'sprintWeekend': False,
    },
    {
        'id': '2026_r23', 'round': 23,
        'nameHu': 'Katari Nagydíj', 'nameEn': 'Qatar Grand Prix',
        'circuit': 'Lusail International Circuit', 'country': 'Katar', 'countryCode': 'QA',
        'raceDate': hu_to_utc(2026, 11, 29, 17, 0, CET),
        'sprintWeekend': False,
    },
    {
        'id': '2026_r24', 'round': 24,
        'nameHu': 'Abu Dhabi Nagydíj', 'nameEn': 'Abu Dhabi Grand Prix',
        'circuit': 'Yas Marina Circuit', 'country': 'Abu Dhabi', 'countryCode': 'AE',
        'raceDate': hu_to_utc(2026, 12, 6, 14, 0, CET),
        'sprintWeekend': False,
    },
]

# ============================================================
# TEAMS
# ============================================================
teams = [
    {
        'id': 'mclaren',
        'nameShort': 'McLaren',
        'nameFull': 'McLaren Mastercard F1 Team',
        'company': 'McLaren Racing Limited',
        'chassis': 'McLaren',
        'engine': 'Mercedes',
        'color': '#FF8700',
        'country': 'GB',
    },
    {
        'id': 'mercedes',
        'nameShort': 'Mercedes',
        'nameFull': 'Mercedes-AMG Petronas Formula One Team',
        'company': 'Mercedes-Benz Grand Prix Limited',
        'chassis': 'Mercedes',
        'engine': 'Mercedes',
        'color': '#27F4D2',
        'country': 'DE',
    },
    {
        'id': 'red_bull',
        'nameShort': 'Red Bull',
        'nameFull': 'Oracle Red Bull Racing',
        'company': 'Red Bull Racing Limited',
        'chassis': 'Red Bull Racing',
        'engine': 'Red Bull Ford',
        'color': '#3671C6',
        'country': 'AT',
    },
    {
        'id': 'ferrari',
        'nameShort': 'Ferrari',
        'nameFull': 'Scuderia Ferrari HP',
        'company': 'Ferrari S.p.A',
        'chassis': 'Ferrari',
        'engine': 'Ferrari',
        'color': '#E8002D',
        'country': 'IT',
    },
    {
        'id': 'williams',
        'nameShort': 'Williams',
        'nameFull': 'Atlassian Williams F1 Team',
        'company': 'Williams Grand Prix Engineering Limited',
        'chassis': 'Atlassian Williams',
        'engine': 'Mercedes',
        'color': '#64C4FF',
        'country': 'GB',
    },
    {
        'id': 'racing_bulls',
        'nameShort': 'Racing Bulls',
        'nameFull': 'Visa Cash App Racing Bulls Formula One Team',
        'company': 'Racing Bulls S.p.A.',
        'chassis': 'Racing Bulls',
        'engine': 'Red Bull Ford',
        'color': '#6692FF',
        'country': 'IT',
    },
    {
        'id': 'aston_martin',
        'nameShort': 'Aston Martin',
        'nameFull': 'Aston Martin Aramco Formula One Team',
        'company': 'AMR GP Limited',
        'chassis': 'Aston Martin Aramco',
        'engine': 'Honda',
        'color': '#229971',
        'country': 'GB',
    },
    {
        'id': 'haas',
        'nameShort': 'Haas',
        'nameFull': 'TGR Haas F1 Team',
        'company': 'Haas Formula LLC',
        'chassis': 'Haas',
        'engine': 'Ferrari',
        'color': '#B6BABD',
        'country': 'US',
    },
    {
        'id': 'audi',
        'nameShort': 'Audi',
        'nameFull': 'Audi Revolut F1 Team',
        'company': 'Sauber Motorsport AG',
        'chassis': 'Audi',
        'engine': 'Audi',
        'color': '#00E701',
        'country': 'CH',
    },
    {
        'id': 'alpine',
        'nameShort': 'Alpine',
        'nameFull': 'BWT Alpine Formula One Team',
        'company': 'Alpine Racing Limited',
        'chassis': 'Alpine',
        'engine': 'Mercedes',
        'color': '#FF87BC',
        'country': 'FR',
    },
    {
        'id': 'cadillac',
        'nameShort': 'Cadillac',
        'nameFull': 'Cadillac Formula 1 Team',
        'company': 'TWG Cadillac Formula 1 Team LLC',
        'chassis': 'Cadillac',
        'engine': 'Ferrari',
        'color': '#1E1E1E',
        'country': 'US',
    },
]

# ============================================================
# DRIVERS
# ============================================================
drivers = [
    {'id': 'norris', 'number': 1, 'firstName': 'Lando', 'lastName': 'Norris', 'teamId': 'mclaren', 'country': 'GB', 'abbr': 'NOR'},
    {'id': 'piastri', 'number': 81, 'firstName': 'Oscar', 'lastName': 'Piastri', 'teamId': 'mclaren', 'country': 'AU', 'abbr': 'PIA'},
    {'id': 'russell', 'number': 63, 'firstName': 'George', 'lastName': 'Russell', 'teamId': 'mercedes', 'country': 'GB', 'abbr': 'RUS'},
    {'id': 'antonelli', 'number': 12, 'firstName': 'Andrea Kimi', 'lastName': 'Antonelli', 'teamId': 'mercedes', 'country': 'IT', 'abbr': 'ANT'},
    {'id': 'verstappen', 'number': 3, 'firstName': 'Max', 'lastName': 'Verstappen', 'teamId': 'red_bull', 'country': 'NL', 'abbr': 'VER'},
    {'id': 'hadjar', 'number': 6, 'firstName': 'Isack', 'lastName': 'Hadjar', 'teamId': 'red_bull', 'country': 'FR', 'abbr': 'HAD'},
    {'id': 'leclerc', 'number': 16, 'firstName': 'Charles', 'lastName': 'Leclerc', 'teamId': 'ferrari', 'country': 'MC', 'abbr': 'LEC'},
    {'id': 'hamilton', 'number': 44, 'firstName': 'Lewis', 'lastName': 'Hamilton', 'teamId': 'ferrari', 'country': 'GB', 'abbr': 'HAM'},
    {'id': 'albon', 'number': 23, 'firstName': 'Alexander', 'lastName': 'Albon', 'teamId': 'williams', 'country': 'TH', 'abbr': 'ALB'},
    {'id': 'sainz', 'number': 55, 'firstName': 'Carlos', 'lastName': 'Sainz', 'teamId': 'williams', 'country': 'ES', 'abbr': 'SAI'},
    {'id': 'lindblad', 'number': 41, 'firstName': 'Arvid', 'lastName': 'Lindblad', 'teamId': 'racing_bulls', 'country': 'GB', 'abbr': 'LIN'},
    {'id': 'lawson', 'number': 30, 'firstName': 'Liam', 'lastName': 'Lawson', 'teamId': 'racing_bulls', 'country': 'NZ', 'abbr': 'LAW'},
    {'id': 'stroll', 'number': 18, 'firstName': 'Lance', 'lastName': 'Stroll', 'teamId': 'aston_martin', 'country': 'CA', 'abbr': 'STR'},
    {'id': 'alonso', 'number': 14, 'firstName': 'Fernando', 'lastName': 'Alonso', 'teamId': 'aston_martin', 'country': 'ES', 'abbr': 'ALO'},
    {'id': 'ocon', 'number': 31, 'firstName': 'Esteban', 'lastName': 'Ocon', 'teamId': 'haas', 'country': 'FR', 'abbr': 'OCO'},
    {'id': 'bearman', 'number': 87, 'firstName': 'Oliver', 'lastName': 'Bearman', 'teamId': 'haas', 'country': 'GB', 'abbr': 'BEA'},
    {'id': 'hulkenberg', 'number': 27, 'firstName': 'Nico', 'lastName': 'Hülkenberg', 'teamId': 'audi', 'country': 'DE', 'abbr': 'HUL'},
    {'id': 'bortoleto', 'number': 5, 'firstName': 'Gabriel', 'lastName': 'Bortoleto', 'teamId': 'audi', 'country': 'BR', 'abbr': 'BOR'},
    {'id': 'gasly', 'number': 10, 'firstName': 'Pierre', 'lastName': 'Gasly', 'teamId': 'alpine', 'country': 'FR', 'abbr': 'GAS'},
    {'id': 'colapinto', 'number': 43, 'firstName': 'Franco', 'lastName': 'Colapinto', 'teamId': 'alpine', 'country': 'AR', 'abbr': 'COL'},
    {'id': 'perez', 'number': 11, 'firstName': 'Sergio', 'lastName': 'Pérez', 'teamId': 'cadillac', 'country': 'MX', 'abbr': 'PER'},
    {'id': 'bottas', 'number': 77, 'firstName': 'Valtteri', 'lastName': 'Bottas', 'teamId': 'cadillac', 'country': 'FI', 'abbr': 'BOT'},
]

# ============================================================
# UPLOAD
# ============================================================
batch = db.batch()

# Delete old races first
print("Deleting old races...")
old_races = db.collection('races').get()
for doc in old_races:
    batch.delete(doc.reference)

# Upload races
print(f"Uploading {len(races)} races...")
for race in races:
    rid = race.pop('id')
    race['flagEmoji'] = flag(race['countryCode'])
    ref = db.collection('races').document(rid)
    batch.set(ref, race)

print(f"Uploading {len(teams)} teams...")
for team in teams:
    tid = team.pop('id')
    ref = db.collection('teams').document(tid)
    batch.set(ref, team)

print(f"Uploading {len(drivers)} drivers...")
for driver in drivers:
    did = driver.pop('id')
    driver['flagEmoji'] = flag(driver['country'])
    ref = db.collection('drivers').document(did)
    batch.set(ref, driver)

print("Committing batch...")
batch.commit()
print("Done! All 2026 F1 data uploaded successfully.")

# Verify
print("\n--- Verification ---")
races_count = len(db.collection('races').get())
teams_count = len(db.collection('teams').get())
drivers_count = len(db.collection('drivers').get())
print(f"Races: {races_count}")
print(f"Teams: {teams_count}")
print(f"Drivers: {drivers_count}")

# Print first 3 races
for doc in db.collection('races').order_by('round').limit(3).get():
    d = doc.to_dict()
    print(f"  R{d['round']}: {d['nameHu']} - {d['raceDate']} (sprint: {d['sprintWeekend']})")

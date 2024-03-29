
def get_team_data(team):
    if team is None:
        return None

    return {
        'id': team.id,
        'name': team.name,
    }


def get_pilot_data(pilot):
    if pilot is None:
        return None

    return {
        'id': pilot.id,
        'name': pilot.name,
    }

def get_season_data(season):
    if season is None:
        return None

    return {
        'id': season.id,
        'year': season.year,
        'is_ended': season.is_ended,
    }

def get_race_data(race):
    if race is None:
        return None

    return {
        'id': race.id,
        'name': race.name,
        'date': race.date,
    }
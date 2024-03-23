import datetime
from threading import Thread

from details.models import f1_team, f1_pilot, f1_race, f1_season
from tips.models import f1_question, f1_question_translation
from user.models import User, f1_language


def checkDatabasestateanddata():
    user = User.objects.first()
    if user is None:
        new_user = User(
            email="birkusz20@gmail.com",
            nickname="birek",
            is_active=True,
            is_staff=True,
            is_superuser=True,
            language_id=1
        )
        new_user.set_password("123456")
        new_user.save()

        races = {}
        races["BAHRAIN GP"] = datetime.datetime(2024, 3, 2, 16, 0)
        races["SAUDI ARABIAN GP"] = datetime.datetime(2024, 3, 9, 18, 0)
        races["AUSTRALIAN GP"] = datetime.datetime(2024, 3, 24, 5, 0)
        races["JAPANESE GP"] = datetime.datetime(2024, 4, 7, 7, 0)
        races["CHINESE GP"] = datetime.datetime(2024, 4, 21, 9, 0)
        races["MIAMI GP"] = datetime.datetime(2024, 5, 5, 22, 0)
        races["EMILIA ROMAGNA GP"] = datetime.datetime(2024, 5, 19, 15, 0)
        races["MONACO GP"] = datetime.datetime(2024, 5, 26, 15, 0)
        races["CANADIAN GP"] = datetime.datetime(2024, 6, 9, 20, 0)
        races["SPANISH GP"] = datetime.datetime(2024, 6, 23, 15, 0)
        races["AUSTRIAN GP"] = datetime.datetime(2024, 6, 30, 15, 0)
        races["BRITISH GP"] = datetime.datetime(2024, 7, 7, 16, 0)
        races["HUNGARIAN GP"] = datetime.datetime(2024, 7, 21, 15, 0)
        races["BELGIAN GP"] = datetime.datetime(2024, 7, 28, 15, 0)
        races["DUTCH GP"] = datetime.datetime(2024, 8, 25, 15, 0)
        races["ITALIAN GP"] = datetime.datetime(2024, 9, 1, 15, 0)
        races["AZERBAIJAN GP"] = datetime.datetime(2024, 9, 15, 13, 0)
        races["SINGAPORE GP"] = datetime.datetime(2024, 9, 22, 14, 0)
        races["UNITED STATES GP"] = datetime.datetime(2024, 10, 20, 21, 0)
        races["MEXICAN GP"] = datetime.datetime(2024, 10, 27, 21, 0)
        races["BRAZILIAN GP"] = datetime.datetime(2024, 11, 3, 18, 0)
        races["LAS VEGAS GP"] = datetime.datetime(2024, 11, 24, 7, 0)
        races["QATAR GP"] = datetime.datetime(2024, 12, 1, 18, 0)
        races["ABU DHABI GP"] = datetime.datetime(2024, 12, 8, 14, 0)

        new_season = f1_season.objects.create(year=2024)

        for key, value in races.items():
            f1_race.objects.create(name=key, date=value, season=new_season)




        teams = [
            "Alpine",
            "Aston Martin",
            "Ferrari",
            "Haas",
            "McLaren",
            "Mercedes",
            "Red Bull",
            "Sauber(Alfa Romeo)",
            "VCARB(AlphaTauri)",
            "Williams"
        ]

        drivers = [
            "Pierre Gasly",
            "Esteban Ocon",
            "Fernando Alonso",
            "Lance Stroll",
            "Charles Leclerc",
            "Carlos Sainz",
            "Nico Hulkenberg",
            "Kevin Magnussen",
            "Lando Norris",
            "Oscar Piastri",
            "Lewis Hamilton",
            "George Russell",
            "Sergio Perez",
            "Max Verstappen",
            "Valtteri Bottas",
            "Zhou Guanyu",
            "Daniel Ricciardo",
            "Yuki Tsunoda",
            "Alex Albon",
            "Logan Sargeant"
        ]

        questions = {}
        questions["Ki lesz az első?"] = False
        questions["Ki lesz a második?"] = False
        questions["Ki lesz a harmadik?"] = False
        questions["Ki lesz a negyedik?"] = False
        questions["Ki lesz az ötödik?"] = False
        questions["Ki lesz a hatodik?"] = False
        questions["Ki lesz a hetedik?"] = False
        questions["Ki lesz a nyolcadik?"] = False
        questions["Ki lesz a kilencedik?"] = False
        questions["Ki lesz a tizedik?"] = False
        questions["Ki lesz a tizenegyedik?"] = False
        questions["Ki lesz a tizenkettedik?"] = False
        questions["Ki lesz a tizenharmadik?"] = False
        questions["Ki lesz a tizennegyedik?"] = False
        questions["Ki lesz a tizenötödik?"] = False
        questions["Legtöbb kör egy gumival?"] = True
        questions["Mennyi az első és a második közötti időkülönbség(másodperc)?"] = True
        questions["Mennyi lesz a legtöbb boxkiállás?"] = True
        questions["Kié lesz a leggyorsabb kör?"] = False
        questions["Ki lesz az első kieső?"] = False
        questions["Ki lesz a második kieső?"] = False
        questions["Ki lesz a harmadik kieső?"] = False
        questions["Ki lesz aki a legtöbbet esik vissza az első körben?"] = False
        questions["Ki az aki a legtöbbet javít a pozicióján?"] = False

        languages = {}
        languages["hu"] = "Magyar"
        languages["en"] = "English"

        for team in teams:
            if f1_team.objects.filter(name=team).first() is not None:
                continue
            team = f1_team.objects.create(name=team)
            team.save()

        for name in drivers:
            if f1_pilot.objects.filter(name=name).first() is not None:
                continue
            driver = f1_pilot()
            driver.name = name

            if driver.name == "Pierre Gasly":
                driver.team = f1_team.objects.get(name="Alpine")
            elif driver.name == "Esteban Ocon":
                driver.team = f1_team.objects.get(name="Alpine")
            elif driver.name == "Fernando Alonso":
                driver.team = f1_team.objects.get(name="Aston Martin")
            elif driver.name == "Lance Stroll":
                driver.team = f1_team.objects.get(name="Aston Martin")
            elif driver.name == "Charles Leclerc":
                driver.team = f1_team.objects.get(name="Ferrari")
            elif driver.name == "Carlos Sainz":
                driver.team = f1_team.objects.get(name="Ferrari")
            elif driver.name == "Nico Hulkenberg":
                driver.team = f1_team.objects.get(name="Haas")
            elif driver.name == "Kevin Magnussen":
                driver.team = f1_team.objects.get(name="Haas")
            elif driver.name == "Lando Norris":
                driver.team = f1_team.objects.get(name="McLaren")
            elif driver.name == "Oscar Piastri":
                driver.team = f1_team.objects.get(name="McLaren")
            elif driver.name == "Lewis Hamilton":
                driver.team = f1_team.objects.get(name="Mercedes")
            elif driver.name == "George Russell":
                driver.team = f1_team.objects.get(name="Mercedes")
            elif driver.name == "Sergio Perez":
                driver.team = f1_team.objects.get(name="Red Bull")
            elif driver.name == "Max Verstappen":
                driver.team = f1_team.objects.get(name="Red Bull")
            elif driver.name == "Valtteri Bottas":
                driver.team = f1_team.objects.get(name="Sauber(Alfa Romeo)")
            elif driver.name == "Zhou Guanyu":
                driver.team = f1_team.objects.get(name="Sauber(Alfa Romeo)")
            elif driver.name == "Daniel Ricciardo":
                driver.team = f1_team.objects.get(name="VCARB(AlphaTauri)")
            elif driver.name == "Yuki Tsunoda":
                driver.team = f1_team.objects.get(name="VCARB(AlphaTauri)")
            elif driver.name == "Alex Albon":
                driver.team = f1_team.objects.get(name="Williams")
            elif driver.name == "Logan Sargeant":
                driver.team = f1_team.objects.get(name="Williams")

            driver.save()

        for key, value in languages.items():
            if f1_language.objects.filter(code=key).first() is not None:
                continue
            language = f1_language.objects.create(name=value, code=key)
            language.save()

        for key, value in questions.items():
            question = f1_question.objects.create(is_number=value)
            question.save()

            for language in ["hu", "en"]:
                language = f1_language.objects.filter(code=language).first()
                if language is not None:
                    if language.code == "hu":
                        f1_question_translation.objects.create(question=question, language=language, text=key)

                    else:
                        if language.code == "en":
                            if key == "Ki lesz az első?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the first?")

                            elif key == "Ki lesz a második?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the second?")

                            elif key == "Ki lesz a harmadik?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the third?")

                            elif key == "Ki lesz a negyedik?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the fourth?")

                            elif key == "Ki lesz az ötödik?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the fifth?")

                            elif key == "Ki lesz a hatodik?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the sixth?")

                            elif key == "Ki lesz a hetedik?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the seventh?")

                            elif key == "Ki lesz a nyolcadik?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the eighth?")

                            elif key == "Ki lesz a kilencedik?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the ninth?")

                            elif key == "Ki lesz a tizedik?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the tenth?")

                            elif key == "Ki lesz a tizenegyedik?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the eleventh?")

                            elif key == "Ki lesz a tizenkettedik?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the twelfth?")

                            elif key == "Ki lesz a tizenharmadik?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the thirteenth?")

                            elif key == "Ki lesz a tizennegyedik?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the fourteenth?")

                            elif key == "Ki lesz a tizenötödik?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the fifteenth?")

                            elif key == "Legtöbb kör egy gumival?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Most laps with one tire?")

                            elif key == "Mennyi az első és a második közötti időkülönbség(másodperc)?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="What is the time difference between the first and the second(second)?")

                            elif key == "Mennyi lesz a legtöbb boxkiállás?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="How many will be the most pit stops?")

                            elif key == "Kié lesz a leggyorsabb kör?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will have the fastest lap?")

                            elif key == "Ki lesz az első kieső?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the first dropout?")

                            elif key == "Ki lesz a második kieső?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the second dropout?")

                            elif key == "Ki lesz a harmadik kieső?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will be the third dropout?")

                            elif key == "Ki lesz aki a legtöbbet esik vissza az első körben?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will fall back the most in the first round?")

                            elif key == "Ki az aki a legtöbbet javít a pozicióján?":
                                f1_question_translation.objects.create(question=question, language=language,
                                                                       text="Who will improve the most on his position?")

                            else:
                                f1_question_translation.objects.create(question=question, language=language, text=key)


        most_laps_with_one_tire = f1_question_translation.objects.filter(text="Most laps with one tire?").first()
        time_difference_between_first_and_second = f1_question_translation.objects.filter(text="What is the time difference between the first and the second(second)?").first()

        if most_laps_with_one_tire is not None:
            most_laps_with_one_tire.question.is_number = True
            most_laps_with_one_tire.closest_number = True
            most_laps_with_one_tire.question.save()


        if time_difference_between_first_and_second is not None:
            time_difference_between_first_and_second.question.is_number = True
            time_difference_between_first_and_second.closest_number = True
            time_difference_between_first_and_second.question.save()

    print("Database is empty, added default data")
    pass



def run_thread_check():
    thread = Thread(target=checkDatabasestateanddata)
    thread.start()

    pass

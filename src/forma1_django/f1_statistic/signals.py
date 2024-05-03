from django.db.models import F

from f1_statistic.models import f1_user_score
from tips.models import f1_question, f1_answer, f1_race_result


def calculate_and_update_user_scores(user, question, correct_answer, user_answer):
    # Determine score
    score = 1 if user_answer.answer == correct_answer else 0

    # Update or create the user's score for the question
    f1_user_score.objects.update_or_create(
        user=user,
        answer=user_answer,
        score = score
    )


def has_closest_number(correct_answer, user_answer):
    # Initialize a variable to keep track of the smallest difference
    difference = float(int(correct_answer)) - float(int(user_answer.answer))

    answers = f1_answer.objects.filter(question=user_answer.question, race = user_answer.race)

    is_closest_number = True
    # Find the closest number to the correct answer
    for answer in answers:
        current_difference = abs(float(int(correct_answer)) - float(int(answer.answer)))
        if current_difference < difference:
            is_closest_number = False
            break

    return is_closest_number





def get_group_2_answers_by_race(race_id):
    group_2_answers = []

    answers = f1_race_result.objects.filter(question__group_id=2, race_id=race_id)

    for user_answer in answers:
        group_2_answers.append(user_answer.answer)

    return set(group_2_answers)  # Return unique answers as a se
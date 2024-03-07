from django.db.models import F

from f1_statistic.models import f1_user_score


def calculate_and_update_user_scores(user, question, correct_answer, user_answer):
    # Determine score
    score = 1 if user_answer == correct_answer else 0

    # Update or create the user's score for the question
    user_score, created = f1_user_score.objects.update_or_create(
        user=user,
        question=question,
        defaults={'score': F('score') + score}  # This assumes you want to increment the score
    )
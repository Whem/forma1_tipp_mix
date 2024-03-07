from details.signals import get_race_data
from tips.models import f1_question_translation


def get_question_data(question, language_id):
    if question is None:
        return None

    translation = f1_question_translation.objects.filter(question=question, language_id=language_id).first()

    return {
        'id': question.id,
        'question': translation.text if translation else '',
        'is_number': question.is_number,
    }


def get_answer_data(answer, language_id):
    if answer is None:
        return None

    return {
        'id': answer.id,
        'question': get_question_data(answer.question,language_id),
        'race': get_race_data(answer.race),
        'answer': answer.answer,
        'created_at': answer.created_at,
    }

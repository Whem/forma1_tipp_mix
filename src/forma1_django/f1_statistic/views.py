from django.db.models import Sum
from django.http import JsonResponse
from drf_spectacular.utils import extend_schema
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from details.models import f1_race
from f1_statistic.models import f1_user_score
from f1_statistic.serializers import PostCompareSerializer, GetUserScoreSerializer, UserScoreStatisticsSerializer
from f1_statistic.signals import calculate_and_update_user_scores, has_closest_number, get_group_2_answers_by_race
from tips.models import f1_race_result, f1_answer, f1_question
from tips.signals import get_question_data
from user.models import User
from user.serializers import SuccessSerializer


class CompareAPIView(APIView):
    permission_classes = (IsAuthenticated,)
    @extend_schema(
        summary="Create compare",
        request=PostCompareSerializer,
        responses={
            200: SuccessSerializer(many=True)})
    def post(self, request):
        serializer = PostCompareSerializer(data=request.data)
        if serializer.is_valid():
            race_id = serializer.validated_data['race_id']
            race_results = f1_race_result.objects.filter(race_id=race_id)
            questions_array = []

            for race_result in race_results:
                question = race_result.question
                correct_answer = race_result.answer
                user_answers = f1_answer.objects.filter(question=question, race_id=race_id)

                for user_answer in user_answers:
                    user = user_answer.user
                    question = user_answer.question

                    if question.group_id != 2:
                        if question.is_number is False:
                            calculate_and_update_user_scores(user, question, correct_answer, user_answer)
                        elif question.is_number is True and question.closest_number is False:
                            calculate_and_update_user_scores(user, question, correct_answer, user_answer)

                        elif question.is_number is True and question.closest_number is True:
                            is_closest_number = has_closest_number( correct_answer, user_answer)

                            if is_closest_number is True:
                                f1_user_score.objects.update_or_create(
                                    user=user,
                                    answer=user_answer,
                                    score=1
                                )
                            else:
                                f1_user_score.objects.update_or_create(
                                    user=user,
                                    answer=user_answer,
                                    score=0
                                )
                    else:

                        # Collect all answers for group_id = 2 within the current race
                        group_2_answers = get_group_2_answers_by_race(race_id)

                        # Check if the user's answer is in the collected group 2 answers for this race
                        if user_answer.answer in group_2_answers:
                            # The user scores 1 if their answer is in the group 2 answers for the current race
                            f1_user_score.objects.update_or_create(
                                user=user,
                                answer=user_answer,
                                score=1
                            )
                        else:
                            # The user scores 0 if their answer is not in the group 2 answers for the current race
                            f1_user_score.objects.update_or_create(
                                user=user,
                                answer=user_answer,
                                score=0
                            )





            return JsonResponse({"success": True}, status=200)
        else:
            return JsonResponse(serializer.errors, status=400)


class GetStatisticsAPIView(APIView):
    permission_classes = (IsAuthenticated,)
    @extend_schema(
        summary="Get statistics",
        parameters=[GetUserScoreSerializer],
        responses={
            200: UserScoreStatisticsSerializer(many=True)})
    def get(self, request):
        serializer = GetUserScoreSerializer(data=request.query_params)
        serializer.is_valid(raise_exception=True)

        range_choice = serializer.validated_data['range_choice']
        user_id = serializer.validated_data.get('user_id')

        users = User.objects.filter(id=user_id) if user_id else User.objects.all()
        statistics_data = []

        for user in users:
            user_data = {
                'user': user.email,
                'scores': []
            }

            if range_choice == 'total':
                total_score = f1_user_score.objects.filter(user=user).aggregate(total_score=Sum('score'))[
                                  'total_score'] or 0
                user_data['scores'].append({'score': total_score, 'detail': 'Total score'})

            elif range_choice == 'race':
                races = f1_race.objects.all()
                for race in races:
                    score = \
                    f1_user_score.objects.filter(user=user, answer__race=race).aggregate(total_score=Sum('score'))[
                        'total_score']
                    if score:
                        user_data['scores'].append({'score': score, 'detail': f'Score for {race.name}'})

            elif range_choice == 'question':
                questions = f1_question.objects.all()
                for question in questions:
                    score = \
                    f1_user_score.objects.filter(user=user, answer__question=question).aggregate(total_score=Sum('score'))[
                        'total_score']
                    if score:
                        user_data['scores'].append({'score': score, 'detail': get_question_data(question, user.language_id)})

            statistics_data.append(user_data)

        response_serializer = UserScoreStatisticsSerializer(statistics_data, many=True)
        return JsonResponse(response_serializer.data, safe=False)

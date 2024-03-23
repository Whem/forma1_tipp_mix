from django.db.models import Sum
from django.http import JsonResponse
from drf_spectacular.utils import extend_schema
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from details.models import f1_race
from f1_statistic.models import f1_user_score
from f1_statistic.serializers import PostCompareSerializer, GetUserScoreSerializer, UserScoreStatisticsSerializer
from f1_statistic.signals import calculate_and_update_user_scores
from tips.models import f1_race_result, f1_answer, f1_question
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
                    answer = user_answer.answer
                    # Compare user answer with the correct answer
                    if answer == correct_answer:
                        calculate_and_update_user_scores(user, question, correct_answer, answer)
                        # Append success response for each correct answer
                        questions_array.append(
                            {"user": user.username, "question": question.question, "status": "correct"})
                    else:
                        # Append failure response for incorrect answers
                        questions_array.append(
                            {"user": user.username, "question": question.question, "status": "incorrect"})

            return JsonResponse({"success": True}, status=200)
        else:
            return JsonResponse(serializer.errors, status=400)


class GetStatisticsAPIView(APIView):
    permission_classes = (IsAuthenticated,)
    @extend_schema(
        summary="Get statistics",
        parameters=[GetUserScoreSerializer],
        responses={
            200: SuccessSerializer(many=True)})
    def get(self, request):
        serializer = GetUserScoreSerializer(data=request.query_params)
        serializer.is_valid(raise_exception=True)

        range_choice = serializer.validated_data['range_choice']
        user_id = serializer.validated_data.get('user_id')

        users = User.objects.filter(id=user_id) if user_id else User.objects.all()
        statistics_data = []

        for user in users:
            user_data = {
                'user': user.username,
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
                    f1_user_score.objects.filter(user=user, answer=question).aggregate(total_score=Sum('score'))[
                        'total_score']
                    if score:
                        user_data['scores'].append({'score': score, 'detail': question.question})

            statistics_data.append(user_data)

        response_serializer = UserScoreStatisticsSerializer(statistics_data, many=True)
        return JsonResponse(response_serializer.data, safe=False)

from django.http import JsonResponse
from drf_spectacular.utils import extend_schema
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from tips.models import f1_question, f1_answer, f1_race_result
from tips.serializers import QuestionSerializer, GetAnswerSerializer, AnswerSerializer, PostAnswerSerializer
from tips.signals import get_question_data, get_answer_data


class QuestionAPIView(APIView):
    permission_classes = (IsAuthenticated,)
    @extend_schema(
        summary="Get questions",
        responses={
            200: QuestionSerializer(many=True)})
    def get(self, request):
        questions = f1_question.objects.all()
        owner = request.user
        questions_array = []

        for question in questions:
            data = get_question_data(question, owner.language_id)
            serializer = QuestionSerializer(data=data)
            serializer.is_valid(raise_exception=True)
            questions_array.append(serializer.validated_data)

        return JsonResponse(questions_array, safe=False)


class AnswerAPIView(APIView):
    permission_classes = (IsAuthenticated,)
    @extend_schema(
        summary="Get answers",
        parameters=[GetAnswerSerializer],
        responses={
            200: AnswerSerializer(many=True)})
    def get(self, request):
        serializer = GetAnswerSerializer(data=request.query_params)
        serializer.is_valid(raise_exception=True)

        user = request.user

        answers = f1_answer.objects.filter(user=user, **serializer.validated_data)

        answers_array = []

        for answer in answers:
            data = get_answer_data(answer, user.language_id)
            serializer = AnswerSerializer(data=data)
            serializer.is_valid(raise_exception=True)
            answers_array.append(serializer.validated_data)

        return JsonResponse(answers_array, safe=False)

    @extend_schema(
        summary="Post answer",
        request=PostAnswerSerializer,
        responses={
            200: AnswerSerializer})
    def post(self, request):
        user = request.user
        serializer = PostAnswerSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        answer = f1_answer.objects.filter(user=user, race_id = serializer.validated_data['race_id'], question_id = serializer.validated_data['question_id']).first()
        if answer is None:
            answer = f1_answer()

        for key in serializer.validated_data:
            if hasattr(answer, key):
                setattr(answer, key, serializer.validated_data[key])
        answer.user = user
        answer.save()

        data = get_answer_data(answer, user.language_id)
        serializer = AnswerSerializer(data=data)
        serializer.is_valid(raise_exception=True)

        return JsonResponse(serializer.validated_data, safe=False)


class RaceResultAPIView(APIView):
    permission_classes = [IsAuthenticated]
    @extend_schema(
        summary="Get race result",
        responses={
            200: AnswerSerializer(many=True)})
    def get(self, request):
        answers = f1_race_result.objects.all()
        user = request.user
        answers_array = []

        for answer in answers:
            data = get_answer_data(answer, user.language_id)
            serializer = AnswerSerializer(data=data)
            serializer.is_valid(raise_exception=True)
            answers_array.append(serializer.validated_data)

        return JsonResponse(answers_array, safe = False)

    @extend_schema(
        summary="Post race result",
        request=PostAnswerSerializer,
        responses={
            200: AnswerSerializer})
    def post(self, request):
        serializer = PostAnswerSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user

        if user.is_staff == False:
            return JsonResponse({"error": "User is not staff"}, status=400, safe=False)

        answer = f1_race_result.objects.filter(race_id=serializer.validated_data["race_id"], question_id=serializer.validated_data["question_id"]).first()
        if answer is None:
            answer = f1_race_result()

        for key, value in serializer.validated_data.items():
            if hasattr(answer, key):
                setattr(answer, key, value)

        answer.save()

        data = get_answer_data(answer, user.language_id)
        serializer = AnswerSerializer(data=data)
        serializer.is_valid(raise_exception=True)

        return JsonResponse(serializer.validated_data, safe=False)
# Create your views here.
from django.http import JsonResponse
from drf_spectacular.utils import extend_schema
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from details.models import f1_team, f1_pilot, f1_race
from f1_admin.serializers import PostRaceSerializer
from tips.models import f1_question, f1_question_translation
from user.models import f1_language
from user.serializers import LoginSerializer, SuccessSerializer


class PostRaceAPIView(APIView):
    permission_classes = (IsAuthenticated,)

    @extend_schema(
        summary="Post Race",
        request=PostRaceSerializer,
        responses={
            200: SuccessSerializer})
    def post(self, request):
        user = request.user
        if user.is_staff == False:
            return JsonResponse({"error": "User is not staff"}, status=400, safe=False)

        serializer = PostRaceSerializer(data=request.data)
        serializer.is_valid(raise_exception
                            =True)

        if "id" in serializer.validated_data and "id" is not None:
            race = f1_race.objects.filter(id=serializer.validated_data["id"]).first()
            if race is None:
                return JsonResponse({"error": "Not found race"}, status=400, safe=False)

        else:
            race = f1_race()

        for key in serializer.validated_data:
            if hasattr(race, key) and key != "id":
                setattr(race, key, serializer.validated_data[key])

        race.save()
        return JsonResponse({"success": True}, status=200, safe=False)

# Create your views here.

from django.http import JsonResponse
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from details.models import f1_team, f1_pilot, f1_race, f1_season
from details.serializers import RaceSerializer, TeamSerializer, PilotSerializer, SeasonSerializer
from details.signals import get_race_data, get_team_data, get_pilot_data, get_season_data
from user.serializers import LoginSerializer


class RaceAPIView(APIView):
    permission_classes = (IsAuthenticated,)

    serializer_class = LoginSerializer

    @extend_schema(
        summary="Get Races",
        responses={
            200: RaceSerializer(many=True)})
    def get(self, request):
        races = f1_race.objects.all()

        races_array = []

        for race in races:
            data = get_race_data(race)
            serializer = RaceSerializer(data=data)
            serializer.is_valid(raise_exception=True)
            races_array.append(serializer.validated_data)

        return JsonResponse(races_array, safe=False)

class CurrentRaceAPIView(APIView):
    permission_classes = (IsAuthenticated,)

    @extend_schema(
        summary = "Get Current",
        responses={
            200: RaceSerializer})
    def get(self, request):
        now = timezone.now()

        # Query the f1_race model for the closest race that is yet to happen
        closest_race = f1_race.objects.filter(date__gte=now).order_by('date').first()

        data = get_race_data(closest_race)
        serializer = RaceSerializer(data=data)
        serializer.is_valid(raise_exception=True)

        # Return the serialized race data
        return JsonResponse(serializer.data, safe=False)


class TeamAPIView(APIView):
    permission_classes = (IsAuthenticated,)

    serializer_class = LoginSerializer

    @extend_schema(
        summary="Get Teams",
        responses={
            200: TeamSerializer(many=True)})
    def get(self, request):
        teams = f1_team.objects.all()

        teams_array = []

        for team in teams:
            data = get_team_data(team)
            serializer = TeamSerializer(data=data)
            serializer.is_valid(raise_exception=True)
            teams_array.append(serializer.validated_data)

        return JsonResponse(teams_array, safe=False)


class PilotAPIView(APIView):
    permission_classes = (IsAuthenticated,)

    serializer_class = LoginSerializer

    @extend_schema(
        summary="Get Pilots",
        responses={
            200: PilotSerializer(many=True)})
    def get(self, request):
        pilots = f1_pilot.objects.all()

        pilots_array = []

        for pilot in pilots:
            data = get_pilot_data(pilot)
            serializer = PilotSerializer(data=data)
            serializer.is_valid(raise_exception=True)
            pilots_array.append(serializer.validated_data)

        return JsonResponse(pilots_array, safe=False)

class SeasonAPIView(APIView):
    permission_classes = (IsAuthenticated,)

    serializer_class = LoginSerializer

    @extend_schema(
        summary="Get Seasons",
        responses = {
            200: SeasonSerializer(many=True)})
    def get(self, request):
        seasons = f1_season.objects.all()

        seasons_array = []

        for season in seasons:
            data = get_season_data(season)
            serializer = SeasonSerializer(data=data)
            serializer.is_valid(raise_exception=True)
            seasons_array.append(serializer.validated_data)

        return JsonResponse(seasons_array, safe=False)



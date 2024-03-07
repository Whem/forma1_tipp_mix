from rest_framework import serializers

class SeasonSerializer(serializers.Serializer):
    id = serializers.IntegerField
    year = serializers.IntegerField
    is_ended = serializers.BooleanField(default=False)

class TeamSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()


class PilotSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    team = TeamSerializer()


class RaceSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    location = serializers.CharField()
    date = serializers.DateField()
    time = serializers.TimeField()
    season = SeasonSerializer()

from rest_framework import serializers

from details.models import f1_race


class PostRaceSerializer(serializers.Serializer):
    id = serializers.IntegerField( allow_null=True, required=False)
    name = serializers.CharField()
    location = serializers.CharField()
    date = serializers.DateField()
    time = serializers.TimeField()

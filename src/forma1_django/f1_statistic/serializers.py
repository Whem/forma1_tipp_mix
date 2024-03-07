from rest_framework import serializers


class GetUserScoreSerializer(serializers.Serializer):
    range_choice = serializers.ChoiceField(choices=['question', "race", "total"])
    user_id = serializers.IntegerField(required=False, allow_null=True)


class PostCompareSerializer(serializers.Serializer):
    race_id = serializers.IntegerField()


class UserScoreDetailSerializer(serializers.Serializer):
    score = serializers.IntegerField()
    detail = serializers.CharField()

class UserScoreStatisticsSerializer(serializers.Serializer):
    user = serializers.CharField()
    scores = UserScoreDetailSerializer(many=True)
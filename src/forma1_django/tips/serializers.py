from rest_framework import serializers

from details.serializers import RaceSerializer


class QuestionSerializer(serializers.Serializer):
    question = serializers.CharField()


class AnswerSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    race = RaceSerializer()
    question = QuestionSerializer()
    answer = serializers.CharField()


class GetAnswerSerializer(serializers.Serializer):
    id = serializers.IntegerField(required=False, allow_null=True)
    race_id = serializers.IntegerField()
    question_id = serializers.IntegerField(required=False, allow_null=True)


class PostAnswerSerializer(serializers.Serializer):
    race_id = serializers.IntegerField()
    question_id = serializers.IntegerField()
    answer = serializers.CharField()
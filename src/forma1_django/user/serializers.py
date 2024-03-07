from rest_framework import serializers


class PostLoginSerializer(serializers.Serializer):
    email = serializers.EmailField(max_length=255, required=True)
    password = serializers.CharField(max_length=255, required=True)

class LoginSerializer(serializers.Serializer):
    jwt_token = serializers.CharField(max_length=255, required=True)
    refresh_token = serializers.CharField(max_length=255, required=True)

class PostRegistrationSerializer(serializers.Serializer):
    email = serializers.EmailField(max_length=255, required=True)
    password = serializers.CharField(max_length=255, required=True)
    nickname = serializers.CharField(max_length=255, required=False)
    language_id = serializers.IntegerField(required=False)

class RegistrationSerializer(serializers.Serializer):
    email = serializers.EmailField(max_length=255, required=True)
    password = serializers.CharField(max_length=255, required=True)

class SuccessSerializer(serializers.Serializer):
    success = serializers.BooleanField(required=True)

class PostLogoutSerializer(serializers.Serializer):
    refresh_token = serializers.CharField(required=True)

class LanguageSerializer(serializers.Serializer):
    id = serializers.IntegerField(required=True)
    name = serializers.CharField(max_length=255, required=True)
    code = serializers.CharField(max_length=255, required=True)


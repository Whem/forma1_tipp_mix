from django.contrib.auth import authenticate
from django.http import JsonResponse
from drf_spectacular.utils import extend_schema
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from user.models import User, f1_language
from user.serializers import LoginSerializer, PostRegistrationSerializer, RegistrationSerializer, PostLogoutSerializer, \
    SuccessSerializer, PostLoginSerializer, LanguageSerializer


class LoginAPIView(APIView):
    permission_classes = (AllowAny,)

    serializer_class = LoginSerializer

    @extend_schema(
        summary="Login",
        request=PostLoginSerializer,
        responses={

            200: LoginSerializer})
    def post(self, request):
        serializer = PostLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        if "email" in serializer.validated_data and "password" in serializer.validated_data:
            user = User.objects.filter(email=serializer.data["email"]).first()
            if user is None:
                return JsonResponse({"error": "User not found"}, status=400, safe=False)

            result = authenticate(email=user.email, password=serializer.validated_data['password'])

            if (result is None):
                return JsonResponse({"error": "User not found"}, status=400, safe=False)
            jwt_token = user.token['access']
            refresh_token = user.token['refresh']
            serializer = LoginSerializer(data={'jwt_token': jwt_token, 'refresh_token': refresh_token})
            serializer.is_valid(raise_exception=True)
            return JsonResponse(serializer.data, status=200, safe=False)
        else:
            return JsonResponse(serializer.errors, status=400, safe=False)


class RegistrationAPIView(APIView):
    # Allow any user (authenticated or not) to hit this endpoint.
    permission_classes = (AllowAny,)

    @extend_schema(
        summary="Registration",
        request=PostRegistrationSerializer,
        responses={
            200: SuccessSerializer})
    def post(self, request):
        serializer = PostRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        if User.objects.filter(email=serializer.validated_data['email']).exists():
            return JsonResponse({"error": "User already exists"}, status=400, safe=False)

        if User.objects.filter(nickname=serializer.validated_data['nickname']).exists():
            return JsonResponse({"error": "Username already exists"}, status=400, safe=False)

        if "language_id" not in serializer.validated_data:
            return JsonResponse({"error": "Language not found"}, status=400, safe=False)

        User.objects.create_user(
            email=serializer.validated_data['email'],
            password=serializer.validated_data['password'],
            nickname=serializer.validated_data['nickname'],
            language_id=serializer.validated_data['language_id'],
            is_active=True,
            is_staff=False,
            is_superuser=False
        )

        success_serializer = SuccessSerializer(data={'success': True})
        success_serializer.is_valid(raise_exception=True)
        return JsonResponse(success_serializer.data, status=200, safe=False)


class LogoutAPIView(APIView):
    permission_classes = (IsAuthenticated,)

    @extend_schema(
        summary="Logout",
        request=PostLogoutSerializer,
        responses={
            200: SuccessSerializer})
    def post(self, request):
        token_seri = PostLogoutSerializer(data=request.data)
        token_seri.is_valid(raise_exception=True)

        token = request.data['refresh_token']
        token = RefreshToken(token)
        token.blacklist()
        success_serializer = SuccessSerializer(data={'success': True})
        success_serializer.is_valid(raise_exception=True)
        return JsonResponse(success_serializer.data, status=200, safe=False)


class LanguageApiView(APIView):
    permission_classes = (AllowAny,)

    @extend_schema(
        summary="Get Language",
        responses={
            200: LanguageSerializer(many=True)})
    def get(self, request):
        languages = f1_language.objects.all()

        language_array = []
        for language in languages:
            serializer = LanguageSerializer(data=language.__dict__)
            serializer.is_valid(raise_exception=True)
            language_array.append(serializer.data)

        return JsonResponse(language_array, status=200, safe=False)


class PingAPIView(APIView):
    permission_classes = (AllowAny,)

    @extend_schema(
        summary="Ping",
        responses={
            200: SuccessSerializer})
    def get(self, request):
        success_serializer = SuccessSerializer(data={'success': True})
        success_serializer.is_valid(raise_exception=True)
        return JsonResponse(success_serializer.data, status=200, safe=False)

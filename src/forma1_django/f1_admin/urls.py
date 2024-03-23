from django.urls import path, re_path
from django.views.decorators.csrf import csrf_exempt
from django_email_verification import verify_email_page
from rest_framework_simplejwt.views import TokenRefreshView, TokenVerifyView, TokenBlacklistView

from . import views


urlpatterns = [
    path('admin/add_race', views.PostRaceAPIView.as_view()),
]


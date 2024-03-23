from django.urls import path, re_path
from django.views.decorators.csrf import csrf_exempt
from django_email_verification import verify_email_page
from rest_framework_simplejwt.views import TokenRefreshView, TokenVerifyView, TokenBlacklistView

from . import views


urlpatterns = [
    path('data/races', views.RaceAPIView.as_view()),
    path('data/current_race', views.CurrentRaceAPIView.as_view()),
    path('data/teams', views.TeamAPIView.as_view()),
    path('data/pilots', views.PilotAPIView.as_view()),
]


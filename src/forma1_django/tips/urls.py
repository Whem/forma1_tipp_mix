from django.urls import path, re_path
from django.views.decorators.csrf import csrf_exempt
from django_email_verification import verify_email_page
from rest_framework_simplejwt.views import TokenRefreshView, TokenVerifyView, TokenBlacklistView

from . import views


urlpatterns = [
    path('tips/questions', views.QuestionAPIView.as_view()),
    path('tips/answers', views.AnswerAPIView.as_view()),
    path('tips/race_results', views.RaceResultAPIView.as_view()),

]


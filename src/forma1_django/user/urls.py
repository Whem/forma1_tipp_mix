from django.urls import path

from . import views

urlpatterns = [
    path('user/login', views.LoginAPIView.as_view()),
    path('user/logout', views.LogoutAPIView.as_view()),
    path('user/register', views.RegistrationAPIView.as_view()),
    path('system/language', views.LanguageApiView.as_view()),
    path('system/ping', views.PingAPIView.as_view()),
]


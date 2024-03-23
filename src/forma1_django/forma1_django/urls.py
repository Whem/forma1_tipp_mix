"""
URL configuration for forma1_django project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""

from unittest.mock import patch

from django.contrib import admin
from django.urls import include, re_path
from django.urls import path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView
from rest_framework import routers
from rest_framework.schemas import get_schema_view
from rest_framework_swagger.views import get_swagger_view

from forma1_django.loadings import run_thread_check


def patch_the_method(func):
    def inner(*args, **kwargs):
        with patch('rest_framework.permissions.IsAuthenticated.has_permission', return_value=True):
            response = func(*args, **kwargs)
        return response

    return inner



urlpatterns = [

    path('api/schema/swagger.json', SpectacularAPIView.as_view(), name='schema'),
    # Optional UI:
    path('api/schema/swagger-ui/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),

    path('', include('user.urls')),
    path('', include('f1_admin.urls')),
    path('', include('details.urls')),
    path('', include('tips.urls')),
    path('', include('f1_statistic.urls')),
]
run_thread_check()

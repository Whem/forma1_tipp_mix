from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.utils import timezone
from rest_framework_simplejwt.tokens import RefreshToken

from forma1_django.models import TimestampedModel
from forma1_django.settings import ONLINE_TIMEOUT
from .managers import UserManager


class f1_language(models.Model):
    name = models.CharField(max_length=255)
    code = models.CharField(max_length=255)

    class Meta:
        db_table = 'f1_language'

class User(AbstractBaseUser, PermissionsMixin, TimestampedModel):
    last_action_time = models.DateTimeField(null=True)
    email = models.EmailField(db_index=True, unique=True)
    nickname = models.CharField(max_length=255, blank=True)
    is_staff = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    language_id = models.IntegerField(null=True, blank=True)
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    objects = UserManager()

    class Meta:
        db_table = 'f1_user'

    def __str__(self):
        return self.email

    @property
    def is_online(self) -> bool:
        if not self.last_action_time:
            return False

        time_since_last_action = timezone.now() - self.last_action_time
        return time_since_last_action.total_seconds() < ONLINE_TIMEOUT

    @property
    def token(self):
        """
        Allows us to get a user's token by calling `user.token` instead of
        `user.generate_jwt_token().

        The `@property` decorator above makes this possible. `token` is called
        a "dynamic property".
        """

        refresh = RefreshToken.for_user(self)

        return {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        }

    @property
    def jwt_token(self):
        refresh = RefreshToken.for_user(self)

        return [str(refresh.access_token), str(refresh)]










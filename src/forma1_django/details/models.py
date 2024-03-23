from django.db import models

class f1_season(models.Model):
    year = models.IntegerField()
    is_ended = models.BooleanField(default=False)

    class Meta:
        db_table = "f1_season"

class f1_race(models.Model):
    season = models.ForeignKey(f1_season, on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    date = models.DateTimeField()

    class Meta:
        db_table = "f1_race"


class f1_team(models.Model):
    name = models.CharField(max_length=100)

    class Meta:
        db_table = "f1_team"


# Create your models here.
class f1_pilot(models.Model):
    name = models.CharField(max_length=100)
    team = models.ForeignKey(f1_team, on_delete=models.CASCADE)

    class Meta:
        db_table = "f1_pilot"

from django.db import models

# Create your models here.
class f1_question(models.Model):
    is_number = models.BooleanField(default=False)
    closest_number = models.BooleanField(default=False)

    class Meta:
        db_table = 'f1_question'

class f1_question_translation(models.Model):
    question = models.ForeignKey(f1_question, on_delete=models.CASCADE)
    language = models.ForeignKey("user.f1_language", on_delete=models.CASCADE)
    text = models.TextField()

    class Meta:
        db_table = 'f1_question_translation'

class f1_answer(models.Model):
    user = models.ForeignKey("user.User", on_delete=models.CASCADE)
    question = models.ForeignKey(f1_question, on_delete=models.CASCADE)
    race = models.ForeignKey("details.f1_race", on_delete=models.CASCADE)
    answer = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'f1_answer'

class f1_race_result(models.Model):
    race = models.OneToOneField("details.f1_race", on_delete=models.CASCADE)
    question = models.ForeignKey(f1_question, on_delete=models.CASCADE)
    answer = models.TextField(null=True, blank=True)

    class Meta:
        db_table = "f1_race_result"
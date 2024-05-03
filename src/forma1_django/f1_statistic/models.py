from django.db import models

# Create your models here.

class f1_user_score(models.Model):
    user = models.ForeignKey("user.User", on_delete=models.CASCADE)
    answer = models.ForeignKey("tips.f1_answer", on_delete=models.CASCADE)
    score = models.IntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'f1_user_score'

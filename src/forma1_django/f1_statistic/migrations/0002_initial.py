# Generated by Django 5.0.2 on 2024-03-02 22:34

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('f1_statistic', '0001_initial'),
        ('tips', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='f1_user_score',
            name='answer',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='tips.f1_question'),
        ),
    ]

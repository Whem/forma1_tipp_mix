# Generated by Django 5.0.3 on 2024-04-24 20:45

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('f1_statistic', '0003_initial'),
    ]

    operations = [
        migrations.RenameField(
            model_name='f1_user_score',
            old_name='answer',
            new_name='question',
        ),
    ]
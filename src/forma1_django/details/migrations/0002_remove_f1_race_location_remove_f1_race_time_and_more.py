# Generated by Django 5.0.3 on 2024-03-22 23:24

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('details', '0001_initial'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='f1_race',
            name='location',
        ),
        migrations.RemoveField(
            model_name='f1_race',
            name='time',
        ),
        migrations.AlterField(
            model_name='f1_race',
            name='date',
            field=models.DateTimeField(),
        ),
    ]

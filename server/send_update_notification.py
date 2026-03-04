"""Send push notification to all users about a new app update via FCM topic."""
import sys
import json
import google.auth.transport.requests as google_requests
from google.oauth2 import service_account
import requests

SERVICE_ACCOUNT_FILE = '/root/f1-tipp-server/forma1mix-a6ef77bba89e.json'
PROJECT_ID = 'forma1mix'
FCM_URL = f'https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send'

SCOPES = ['https://www.googleapis.com/auth/firebase.messaging']


def get_access_token():
    creds = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=SCOPES
    )
    creds.refresh(google_requests.Request())
    return creds.token


def send_update_notification(version: str, build: int):
    token = get_access_token()

    message = {
        'message': {
            'topic': 'app_updates',
            'notification': {
                'title': 'F1 Tipp Mix frissítés!',
                'body': f'Új verzió érhető el: v{version} - Frissítsd az appot az újdonságokért!',
            },
            'data': {
                'type': 'app_update',
                'version': version,
                'build': str(build),
            },
            'android': {
                'priority': 'high',
                'notification': {
                    'channel_id': 'app_updates',
                    'icon': 'ic_launcher',
                    'color': '#E10600',
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                },
            },
        }
    }

    resp = requests.post(
        FCM_URL,
        headers={
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json',
        },
        json=message,
    )

    if resp.ok:
        print(f'Push notification sent! Response: {resp.json()}')
    else:
        print(f'Error sending notification: {resp.status_code} {resp.text}')

    return resp.ok


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: python send_update_notification.py <version> <build>')
        sys.exit(1)

    version = sys.argv[1]
    build = int(sys.argv[2])
    send_update_notification(version, build)

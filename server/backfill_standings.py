"""Backfill missing standings fields for existing users in Firestore."""
import time
import firebase_admin
from firebase_admin import credentials, firestore
import google.auth.transport.requests
import requests as http_requests
import json

SERVICE_ACCOUNT = '/root/f1-tipp-server/forma1mix-a6ef77bba89e.json'

# Try REST API approach first if gRPC is quota-limited
cred = credentials.Certificate(SERVICE_ACCOUNT)
try:
    firebase_admin.initialize_app(cred)
except ValueError:
    pass  # Already initialized

# Read project ID from service account
with open(SERVICE_ACCOUNT) as f:
    sa = json.load(f)
PROJECT_ID = sa['project_id']

def rest_api_backfill():
    """Use Firestore REST API to bypass gRPC quota."""
    from google.oauth2 import service_account as sa_mod
    scopes = ['https://www.googleapis.com/auth/datastore']
    credentials_obj = sa_mod.Credentials.from_service_account_file(SERVICE_ACCOUNT, scopes=scopes)
    credentials_obj.refresh(google.auth.transport.requests.Request())
    token = credentials_obj.token
    
    base = f'https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents'
    headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}
    
    # List all users
    print("Fetching users via REST API...")
    resp = http_requests.get(f'{base}/users?pageSize=100', headers=headers)
    if resp.status_code != 200:
        print(f"ERROR listing users: {resp.status_code} {resp.text}")
        return
    
    docs = resp.json().get('documents', [])
    print(f"Found {len(docs)} users")
    
    count = 0
    for doc in docs:
        fields = doc.get('fields', {})
        name_field = fields.get('displayName', {}).get('stringValue', doc['name'].split('/')[-1])
        
        if 'totalPoints' not in fields:
            # PATCH to add missing fields
            doc_path = doc['name']
            update_fields = {
                'fields': {
                    'totalPoints': {'integerValue': '0'},
                    'racePoints': {'integerValue': '0'},
                    'seasonPoints': {'integerValue': '0'},
                    'racesParticipated': {'integerValue': '0'},
                    'correctP1Count': {'integerValue': '0'},
                    'streakBest': {'integerValue': '0'},
                }
            }
            url = f'https://firestore.googleapis.com/v1/{doc_path}?updateMask.fieldPaths=totalPoints&updateMask.fieldPaths=racePoints&updateMask.fieldPaths=seasonPoints&updateMask.fieldPaths=racesParticipated&updateMask.fieldPaths=correctP1Count&updateMask.fieldPaths=streakBest'
            patch_resp = http_requests.patch(url, headers=headers, json=update_fields)
            if patch_resp.status_code == 200:
                count += 1
                print(f'  Fixed: {name_field}')
            else:
                print(f'  ERROR updating {name_field}: {patch_resp.status_code} {patch_resp.text}')
        else:
            pts = fields.get('totalPoints', {}).get('integerValue', '0')
            print(f'  OK: {name_field} ({pts} pts)')
    
    print(f'Backfilled {count} users')

rest_api_backfill()

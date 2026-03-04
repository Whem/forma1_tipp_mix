"""Update Firestore security rules to include groups, invites, and notifications."""
import firebase_admin
from firebase_admin import credentials

from config import SERVICE_ACCOUNT_PATH

RULES = """
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /races/{raceId} {
      allow read: if request.auth != null;
      allow write: if false;
    }

    match /predictions/{predId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.uid == request.auth.uid;
      allow update: if request.auth != null && resource.data.uid == request.auth.uid;
    }

    match /season_predictions/{spId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.uid == request.auth.uid;
      allow update: if request.auth != null && resource.data.uid == request.auth.uid;
    }

    match /achievements/{achId} {
      allow read: if request.auth != null;
      allow write: if false;
    }

    match /live_race/{docId} {
      allow read: if request.auth != null;
      allow write: if false;
    }

    match /groups/{groupId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null
        && (resource.data.creatorUid == request.auth.uid
            || resource.data.memberUids.hasAny([request.auth.uid]));
      allow delete: if request.auth != null && resource.data.creatorUid == request.auth.uid;
    }

    match /group_invites/{inviteId} {
      allow read: if request.auth != null
        && (resource.data.fromUid == request.auth.uid
            || resource.data.toUid == request.auth.uid);
      allow create: if request.auth != null;
      allow update: if request.auth != null
        && (resource.data.toUid == request.auth.uid
            || resource.data.fromUid == request.auth.uid);
    }

    match /notifications/{notifId} {
      allow read: if request.auth != null && resource.data.toUid == request.auth.uid;
      allow create: if request.auth != null;
      allow update: if request.auth != null && resource.data.toUid == request.auth.uid;
    }
  }
}
"""


def main() -> None:
    cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred)

    print("Firestore security rules content:")
    print(RULES)
    print("\n--- NOTE ---")
    print("Firebase Admin SDK cannot deploy Firestore rules programmatically.")
    print("Copy the rules above into Firebase Console > Firestore > Rules tab,")
    print("or deploy via: firebase deploy --only firestore:rules")
    print("Rules file saved to: firestore.rules")

    import os
    rules_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "firestore.rules")
    with open(rules_path, "w") as f:
        f.write(RULES.strip())
    print(f"Saved to: {rules_path}")


if __name__ == "__main__":
    main()

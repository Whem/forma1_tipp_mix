"""One-time script to backfill friendCode for existing users."""
import random
import string

import firebase_admin
from firebase_admin import credentials, firestore

from config import SERVICE_ACCOUNT_PATH

cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()


def generate_code(length: int = 6) -> str:
    chars = string.ascii_uppercase + string.digits
    return "".join(random.choices(chars, k=length))


def get_existing_codes() -> set[str]:
    codes: set[str] = set()
    for doc in db.collection("users").stream():
        data = doc.to_dict()
        fc = data.get("friendCode")
        if fc:
            codes.add(fc)
    return codes


def main() -> None:
    existing_codes = get_existing_codes()
    users = list(db.collection("users").stream())
    updated = 0

    for doc in users:
        data = doc.to_dict()
        if data.get("friendCode"):
            continue
        if data.get("isAI"):
            continue

        code = generate_code()
        while code in existing_codes:
            code = generate_code()

        existing_codes.add(code)
        db.collection("users").document(doc.id).update({"friendCode": code})
        updated += 1
        print(f"  {doc.id} ({data.get('displayName', '?')}) -> {code}")

    print(f"\nDone. Updated {updated} users.")


if __name__ == "__main__":
    main()

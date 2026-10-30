import base64
import json
import os
import firebase_admin
from firebase_admin import credentials, firestore, auth
from dotenv import load_dotenv

load_dotenv()


def _load_credentials():
    # Server (Render...): khóa service account nằm trong biến môi trường, không có file trên đĩa.
    # Chấp nhận JSON thô hoặc JSON đã mã hóa base64. vang
    raw = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON", "").strip()
    if raw:
        if not raw.startswith("{"):
            raw = base64.b64decode(raw).decode("utf-8")
        return credentials.Certificate(json.loads(raw))

    # Máy dev: đọc file serviceAccountKey.json
    service_account_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", "serviceAccountKey.json")
    if os.path.exists(service_account_path):
        return credentials.Certificate(service_account_path)
    return None


if not firebase_admin._apps:
    cred = _load_credentials()
    if cred:
        firebase_admin.initialize_app(cred)
    else:
        # Fallback to default credentials or application default
        firebase_admin.initialize_app()

db = firestore.client()

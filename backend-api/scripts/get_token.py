"""Lấy Firebase ID token của một tài khoản để thử API trên /docs, không cần app hay điện thoại.

Chạy trong backend-api:  python scripts/get_token.py <email>
Cần serviceAccountKey.json (hoặc FIREBASE_SERVICE_ACCOUNT_JSON) như khi chạy server. Chỉ dùng khi dev.
"""
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from firebase_admin import auth  # noqa: E402
from services import firebase_service  # noqa: E402,F401  (khởi tạo Firebase Admin)

# Web API key trong lib/firebase_options.dart (không phải bí mật, app nào cũng chứa)
WEB_API_KEY = os.getenv("FIREBASE_WEB_API_KEY", "AIzaSyBVpj4mPBWy0Af2Cgagycrpj-heb0CKQ8k")


def get_id_token(email: str) -> str:
    user = auth.get_user_by_email(email)
    # Thêm name/picture vào token để /auth/session không ghi đè displayName thành "Người dùng"
    claims = {k: v for k, v in {"name": user.display_name, "picture": user.photo_url}.items() if v}
    custom_token = auth.create_custom_token(user.uid, claims or None).decode()

    req = urllib.request.Request(
        f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key={WEB_API_KEY}",
        data=json.dumps({"token": custom_token, "returnSecureToken": True}).encode(),
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as res:
            return json.load(res)["idToken"]
    except urllib.error.HTTPError as e:
        raise SystemExit(f"Firebase từ chối: {e.read().decode()}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Cách dùng: python scripts/get_token.py <email>")
    token = get_id_token(sys.argv[1])
    if sys.platform == "win32":
        subprocess.run("clip", input=token.encode(), check=True)
        print(f"Đã copy token vào clipboard ({len(token)} ký tự, hết hạn sau 1 giờ).")
    else:
        print(token)

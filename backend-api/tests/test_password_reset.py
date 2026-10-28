"""Chạy (từ thư mục backend-api): python -m pytest -q tests."""
import os
import re
import unittest
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from unittest import mock

# config đọc biến môi trường lúc import: đặt giống test_subscription vì file này có thể chạy trước
os.environ.setdefault("PAYMENT_WEBHOOK_SECRET", "test-secret")
os.environ.setdefault("ENABLE_MOCK_PAY", "false")

import firebase_admin
from fastapi.testclient import TestClient
from firebase_admin import firestore

with mock.patch.object(firebase_admin, "initialize_app"), mock.patch.object(firestore, "client"):
    import main
    from services import password_reset_service as svc


class _FakeSnap:
    def __init__(self, data):
        self._data = data
        self.exists = data is not None

    def to_dict(self):
        return dict(self._data) if self._data is not None else None


class _FakeDoc:
    def __init__(self, store, path):
        self.store, self.path = store, path

    def get(self):
        return _FakeSnap(self.store.get(self.path))

    def set(self, data):
        self.store[self.path] = dict(data)

    def update(self, data):
        self.store[self.path].update(data)

    def delete(self):
        self.store.pop(self.path, None)


class _FakeDb:
    def __init__(self):
        self.store = {}

    def collection(self, name):
        db = self

        class _Col:
            def document(self, doc_id):
                return _FakeDoc(db.store, f"{name}/{doc_id}")
        return _Col()


EMAIL = "an@example.com"


class PasswordResetTest(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(main.app)
        self.fake_db = _FakeDb()
        self.users = {EMAIL: SimpleNamespace(uid="u1", disabled=False)}

        def get_user_by_email(email):
            if email not in self.users:
                raise svc.auth.UserNotFoundError("not found")
            return self.users[email]

        mock.patch.object(svc, "db", self.fake_db).start()
        mock.patch.object(svc.auth, "get_user_by_email", side_effect=get_user_by_email).start()
        self.update_user = mock.patch.object(svc.auth, "update_user").start()
        self.revoke = mock.patch.object(svc.auth, "revoke_refresh_tokens").start()
        self.send = mock.patch.object(svc.mail_service, "send_email").start()

    def tearDown(self):
        mock.patch.stopall()

    def _doc(self):
        return self.fake_db.store[f"password_resets/{svc._doc(EMAIL)[0]}"]

    def _request(self, email=EMAIL):
        return self.client.post("/auth/password-reset/request", json={"email": email})

    def _sent_code(self):
        text = self.send.call_args.args[3]
        return re.search(r"\b(\d{6})\b", text).group(1)

    def _verify(self, code):
        return self.client.post("/auth/password-reset/verify", json={"email": EMAIL, "code": code})

    def test_full_flow(self):
        self.assertEqual(self._request(" An@Example.com ").status_code, 200)
        code = self._sent_code()
        self.assertNotIn(code, str(self._doc()))  # chỉ lưu mã đã băm

        token = self._verify(code).json()["resetToken"]
        res = self.client.post("/auth/password-reset/confirm",
                               json={"email": EMAIL, "resetToken": token, "newPassword": "matkhau123"})
        self.assertEqual(res.status_code, 200)
        self.update_user.assert_called_once_with("u1", password="matkhau123")
        self.revoke.assert_called_once_with("u1")
        self.assertEqual(self.fake_db.store, {})

        # Token chỉ dùng được một lần
        res = self.client.post("/auth/password-reset/confirm",
                               json={"email": EMAIL, "resetToken": token, "newPassword": "khac12345"})
        self.assertEqual(res.status_code, 400)

    def test_unknown_email_looks_sent_but_no_mail(self):
        res = self._request("khongco@example.com")
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.json()["sent"])
        self.send.assert_not_called()

    def test_phone_account_rejected(self):
        res = self._request("0912345678@mousey.local")
        self.assertEqual(res.status_code, 400)
        self.send.assert_not_called()

    def test_resend_cooldown(self):
        self._request()
        self.assertEqual(self._request().status_code, 429)
        self.assertEqual(self.send.call_count, 1)

    def test_wrong_code_then_locked(self):
        self._request()
        code = self._sent_code()
        wrong = "000000" if code != "000000" else "111111"
        for _ in range(svc.config.RESET_CODE_MAX_ATTEMPTS):
            self.assertEqual(self._verify(wrong).status_code, 400)
        # Hết lượt: kể cả mã đúng cũng bị chặn, phải gửi mã mới
        self.assertEqual(self._verify(code).status_code, 429)

    def test_expired_code(self):
        self._request()
        code = self._sent_code()
        self._doc()["codeExpiresAt"] = (datetime.now(timezone.utc) - timedelta(seconds=1)).isoformat()
        self.assertEqual(self._verify(code).status_code, 400)

    def test_code_single_use(self):
        self._request()
        code = self._sent_code()
        self.assertEqual(self._verify(code).status_code, 200)
        self.assertEqual(self._verify(code).status_code, 400)

    def test_short_password_rejected(self):
        self._request()
        token = self._verify(self._sent_code()).json()["resetToken"]
        res = self.client.post("/auth/password-reset/confirm",
                               json={"email": EMAIL, "resetToken": token, "newPassword": "123"})
        self.assertEqual(res.status_code, 400)
        self.update_user.assert_not_called()

    def test_email_language(self):
        self.client.post("/auth/password-reset/request", json={"email": EMAIL, "lang": "en"})
        self.assertIn("password reset code", self.send.call_args.args[1])


if __name__ == "__main__":
    unittest.main()

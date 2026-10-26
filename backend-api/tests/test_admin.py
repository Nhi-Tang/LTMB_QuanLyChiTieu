"""Chạy: python -m unittest discover -s tests (từ thư mục backend-api)."""
import unittest
from unittest import mock

from fastapi.testclient import TestClient

import main
from middleware.auth import verify_firebase_token
from routes import admin as admin_route


class _Snap:
    def __init__(self, data):
        self._data = data
        self.exists = data is not None

    def to_dict(self):
        return dict(self._data) if self._data else None


class _Db:
    def __init__(self, users=None):
        self.users = users or {}
        self.writes = []

    def collection(self, _name):
        db = self

        class _Doc:
            def __init__(self, uid):
                self.uid = uid

            def get(self):
                return _Snap(db.users.get(self.uid))

            def set(self, data, merge=False):
                db.writes.append((self.uid, data, merge))

        class _Col:
            def document(self, uid):
                return _Doc(uid)

        return _Col()


class SetUserActiveTest(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(main.app)
        self.db = _Db({"boss": {"role": "admin"}, "u1": {"role": "user"}})
        patcher = mock.patch.object(admin_route, "db", self.db)
        patcher.start()
        self.addCleanup(patcher.stop)
        self.auth = mock.patch.object(admin_route, "auth").start()
        self.auth.UserNotFoundError = type("UserNotFoundError", (Exception,), {})
        self.addCleanup(mock.patch.stopall)
        self.addCleanup(main.app.dependency_overrides.clear)

    def _login(self, uid, email):
        main.app.dependency_overrides[verify_firebase_token] = lambda: {"uid": uid, "email": email}

    def test_admin_khoa_tai_khoan(self):
        self._login("boss", "boss@example.com")
        res = self.client.post("/admin/users/u1/active", json={"active": False})
        self.assertEqual(res.status_code, 200)
        self.auth.update_user.assert_called_once_with("u1", disabled=True)
        self.auth.revoke_refresh_tokens.assert_called_once_with("u1")
        self.assertEqual(self.db.writes, [("u1", {"isActive": False}, True)])

    def test_mo_khoa_khong_thu_hoi_token(self):
        self._login("boss", "boss@example.com")
        res = self.client.post("/admin/users/u1/active", json={"active": True})
        self.assertEqual(res.status_code, 200)
        self.auth.update_user.assert_called_once_with("u1", disabled=False)
        self.auth.revoke_refresh_tokens.assert_not_called()

    def test_nguoi_dung_thuong_bi_tu_choi(self):
        self._login("u1", "u1@example.com")
        res = self.client.post("/admin/users/boss/active", json={"active": False})
        self.assertEqual(res.status_code, 403)
        self.auth.update_user.assert_not_called()

    def test_khong_tu_khoa_chinh_minh(self):
        self._login("boss", "boss@example.com")
        res = self.client.post("/admin/users/boss/active", json={"active": False})
        self.assertEqual(res.status_code, 400)
        self.auth.update_user.assert_not_called()


if __name__ == "__main__":
    unittest.main()

"""Chạy: python -m unittest discover -s tests (từ thư mục backend-api)."""
import os
import unittest
from unittest import mock

os.environ.setdefault("PAYMENT_WEBHOOK_SECRET", "test-secret")
os.environ.setdefault("ENABLE_MOCK_PAY", "false")

from fastapi.testclient import TestClient
from google.api_core.exceptions import AlreadyExists

import main
from middleware.auth import verify_firebase_token
from services import subscription_service as svc


class _FakeSnap:
    def __init__(self, data):
        self._data = data
        self.exists = data is not None

    def to_dict(self):
        return dict(self._data) if self._data else None


class _FakeDoc:
    def __init__(self, store, path):
        self.store, self.path = store, path

    def get(self, **_):
        return _FakeSnap(self.store.get(self.path))

    def create(self, data):
        if self.path in self.store:
            raise AlreadyExists("exists")
        self.store[self.path] = data

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


class NormalizeTest(unittest.TestCase):
    def test_sepay_payload(self):
        evs = svc._normalize_bank_events({"id": 1, "transferType": "in", "transferAmount": 20000,
                                          "content": "MSYAB12CD34 chuyen tien"})
        self.assertEqual(evs[0]["amount"], 20000)
        self.assertEqual(evs[0]["ref"], "1")

    def test_outgoing_ignored(self):
        self.assertEqual(svc._normalize_bank_events({"transferType": "out", "transferAmount": 5, "content": "x"}), [])

    def test_casso_payload(self):
        evs = svc._normalize_bank_events({"error": 0, "data": [
            {"tid": "T1", "amount": 200000, "description": "MSYZZZZ9999"},
            {"tid": "T2", "amount": -5, "description": "out"},
        ]})
        self.assertEqual([e["ref"] for e in evs], ["T1"])


class WebhookTest(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(main.app)
        self.fake_db = _FakeDb()
        self.fake_db.store["payment_codes/MSYAB12CD34"] = {"uid": "u1", "orderId": "MSYAB12CD34"}
        self.db_patch = mock.patch.object(svc, "db", self.fake_db)
        self.pay_patch = mock.patch.object(svc, "mark_order_paid", return_value={"status": "paid"})
        self.db_patch.start()
        self.mark_paid = self.pay_patch.start()

    def tearDown(self):
        mock.patch.stopall()

    def _post(self, payload, secret="test-secret"):
        return self.client.post("/subscription/webhook/bank", json=payload,
                                headers={"Authorization": f"Apikey {secret}"})

    def test_rejects_wrong_secret(self):
        self.assertEqual(self._post({}, secret="nope").status_code, 401)

    def test_marks_order_paid_once(self):
        payload = {"id": 99, "transferType": "in", "transferAmount": 20000, "content": "ck msyab12cd34"}
        first = self._post(payload).json()
        second = self._post(payload).json()
        self.assertEqual(first["results"][0]["status"], "paid")
        self.assertEqual(second["results"][0]["status"], "duplicate")
        self.mark_paid.assert_called_once_with("u1", "MSYAB12CD34", source="bank_transfer",
                                               paid_amount=20000, payment_ref="99")

    def test_unrelated_transfer_ignored(self):
        res = self._post({"id": 5, "transferType": "in", "transferAmount": 1000, "content": "tien an"}).json()
        self.assertEqual(res["results"][0]["status"], "ignored")
        self.mark_paid.assert_not_called()

    def test_failed_grant_can_be_retried(self):
        self.mark_paid.side_effect = RuntimeError("firestore down")
        payload = {"id": 7, "transferType": "in", "transferAmount": 20000, "content": "MSYAB12CD34"}
        self.assertEqual(self._post(payload).json()["results"][0]["status"], "error")
        self.assertNotIn("payment_events/7", self.fake_db.store)


class AuthAndMockPayTest(unittest.TestCase):
    def setUp(self):
        main.app.dependency_overrides[verify_firebase_token] = lambda: {"uid": "u1"}
        self.client = TestClient(main.app)

    def tearDown(self):
        main.app.dependency_overrides.clear()

    def test_mock_pay_disabled_by_default(self):
        res = self.client.post("/subscription/mock-pay", json={"orderId": "MSYAB12CD34"})
        self.assertEqual(res.status_code, 403)

    def test_invalid_plan_rejected(self):
        res = self.client.post("/subscription/create-order", json={"planType": "lifetime", "amount": 1})
        self.assertEqual(res.status_code, 400)

    def test_requires_token(self):
        main.app.dependency_overrides.clear()
        self.assertIn(self.client.get("/subscription/status").status_code, (401, 403))


if __name__ == "__main__":
    unittest.main()

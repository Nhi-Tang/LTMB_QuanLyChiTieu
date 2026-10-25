from datetime import datetime, timedelta, timezone
from urllib.parse import quote
import logging
import re
import secrets
import string

from fastapi import HTTPException
from firebase_admin import firestore
from google.api_core.exceptions import AlreadyExists

import config
from services.firebase_service import db

logger = logging.getLogger("uvicorn.error")

_CODE_ALPHABET = string.ascii_uppercase + string.digits
_CODE_RE = re.compile(rf"{re.escape(config.PAYMENT_CODE_PREFIX)}[A-Z0-9]{{8}}")


# ---------------------------------------------------------------------------
# Tiện ích thời gian (luôn lưu ISO-8601 có múi giờ UTC)
# ---------------------------------------------------------------------------

def _now() -> datetime:
    return datetime.now(timezone.utc)


def _parse_dt(value):
    if not value or not isinstance(value, str):
        return None
    try:
        dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    # Dữ liệu cũ lưu không kèm múi giờ: coi như UTC
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


def _is_active_pro(user_data: dict) -> bool:
    exp = _parse_dt(user_data.get("proExpiredAt"))
    return user_data.get("plan") == "pro" and exp is not None and exp > _now()


def _user_ref(uid: str):
    return db.collection("users").document(uid)


# ---------------------------------------------------------------------------
# Cấp quyền PRO (gọi bên trong transaction)
# ---------------------------------------------------------------------------

def _apply_grant(transaction, user_ref, user_data: dict, plan_type: str, source: str,
                 order_id: str = None, amount: int = 0) -> dict:
    now = _now()
    base_time = now
    current_exp = _parse_dt(user_data.get("proExpiredAt"))
    # Gia hạn nối tiếp nếu gói hiện tại còn hiệu lực
    if user_data.get("plan") == "pro" and current_exp and current_exp > now:
        base_time = current_exp

    new_expiry = base_time + timedelta(days=config.PLAN_DAYS[plan_type])
    updates = {
        "plan": "pro",
        "planType": plan_type,
        "planSource": source,
        "proExpiredAt": new_expiry.isoformat(),
        "updatedAt": now.isoformat(),
    }
    if plan_type == "trial":
        updates["trialUsed"] = True
    transaction.set(user_ref, updates, merge=True)

    sub_ref = user_ref.collection("subscriptions").document()
    transaction.set(sub_ref, {
        "id": sub_ref.id,
        "planType": plan_type,
        "source": source,
        "orderId": order_id,
        "amount": amount,
        "startedAt": now.isoformat(),
        "expiredAt": new_expiry.isoformat(),
    })

    return {
        "plan": "pro",
        "planType": plan_type,
        "planSource": source,
        "proExpiredAt": new_expiry.isoformat(),
        "subscriptionId": sub_ref.id,
    }


# ---------------------------------------------------------------------------
# Trạng thái gói & dùng thử
# ---------------------------------------------------------------------------

def get_status(uid: str) -> dict:
    user_ref = _user_ref(uid)
    user_doc = user_ref.get()
    data = user_doc.to_dict() if user_doc.exists else {}

    plan = data.get("plan", "free")
    pro_expired_at = data.get("proExpiredAt")
    remaining_days = 0

    if plan == "pro":
        exp = _parse_dt(pro_expired_at)
        if exp and exp > _now():
            remaining_days = (exp - _now()).days
        else:
            plan = "free"
            if user_doc.exists:
                user_ref.update({"plan": "free", "updatedAt": _now().isoformat()})

    return {
        "plan": plan,
        "planType": data.get("planType"),
        "proExpiredAt": pro_expired_at,
        "trialUsed": data.get("trialUsed", False),
        "remainingDays": remaining_days,
        "serverTime": _now().isoformat(),
    }


@firestore.transactional
def _start_trial_txn(transaction, user_ref):
    snap = user_ref.get(transaction=transaction)
    data = snap.to_dict() if snap.exists else {}
    if data.get("trialUsed") or _is_active_pro(data):
        raise HTTPException(
            status_code=409,
            detail="Bạn đã sử dụng quyền dùng thử hoặc đang sở hữu gói PRO.",
        )
    return _apply_grant(transaction, user_ref, data, "trial", source="trial")


def start_trial(uid: str) -> dict:
    return _start_trial_txn(db.transaction(), _user_ref(uid))


# ---------------------------------------------------------------------------
# Đơn hàng
# ---------------------------------------------------------------------------

def _new_payment_code() -> str:
    for _ in range(5):
        code = config.PAYMENT_CODE_PREFIX + "".join(secrets.choice(_CODE_ALPHABET) for _ in range(8))
        if not db.collection("payment_codes").document(code).get().exists:
            return code
    raise HTTPException(status_code=500, detail="Không tạo được mã thanh toán, vui lòng thử lại.")


def _vietqr_url(amount: int, content: str) -> str:
    return (
        f"https://img.vietqr.io/image/{config.PAYMENT_BANK_ID}-{config.PAYMENT_ACCOUNT_NO}-compact2.png"
        f"?amount={amount}&addInfo={quote(content)}&accountName={quote(config.PAYMENT_ACCOUNT_NAME)}"
    )


def _public_order(order: dict) -> dict:
    keys = (
        "orderId", "status", "planType", "amount", "bank", "bankId", "accountNo",
        "accountName", "content", "qrUrl", "createdAt", "expiresAt", "paidAt",
    )
    return {k: order.get(k) for k in keys}


def create_order(uid: str, plan_type: str) -> dict:
    if plan_type not in config.PLAN_PRICES:
        raise HTTPException(status_code=400, detail="Loại gói không hợp lệ (monthly hoặc yearly)")

    # Giá luôn lấy từ server, không tin số tiền client gửi lên
    amount = config.PLAN_PRICES[plan_type]
    code = _new_payment_code()
    now = _now()

    order = {
        "orderId": code,
        "uid": uid,
        "planType": plan_type,
        "amount": amount,
        "status": "pending",
        "bank": config.PAYMENT_BANK_NAME,
        "bankId": config.PAYMENT_BANK_ID,
        "accountNo": config.PAYMENT_ACCOUNT_NO,
        "accountName": config.PAYMENT_ACCOUNT_NAME,
        "content": code,
        "qrUrl": _vietqr_url(amount, code),
        "createdAt": now.isoformat(),
        "expiresAt": (now + timedelta(minutes=config.ORDER_TTL_MINUTES)).isoformat(),
    }

    batch = db.batch()
    batch.set(_user_ref(uid).collection("orders").document(code), order)
    # Chỉ mục mã thanh toán -> đơn hàng, để webhook tra cứu nhanh
    batch.set(db.collection("payment_codes").document(code), {
        "uid": uid,
        "orderId": code,
        "createdAt": now.isoformat(),
    })
    batch.commit()
    return _public_order(order)


def check_order_status(uid: str, order_id: str) -> dict:
    order_ref = _user_ref(uid).collection("orders").document(order_id)
    order_doc = order_ref.get()
    if not order_doc.exists:
        raise HTTPException(status_code=404, detail="Không tìm thấy đơn hàng")

    order = order_doc.to_dict()
    expires_at = _parse_dt(order.get("expiresAt"))
    if order.get("status") == "pending" and expires_at and expires_at < _now():
        order_ref.update({"status": "expired"})
        order["status"] = "expired"
    return _public_order(order)


@firestore.transactional
def _mark_paid_txn(transaction, order_ref, user_ref, source: str, paid_amount, payment_ref):
    order_snap = order_ref.get(transaction=transaction)
    if not order_snap.exists:
        raise HTTPException(status_code=404, detail="Không tìm thấy đơn hàng")
    user_snap = user_ref.get(transaction=transaction)

    order = order_snap.to_dict()
    if order.get("status") == "paid":
        return {"status": "paid", "alreadyPaid": True, "orderId": order.get("orderId")}

    expected = int(order.get("amount", 0))
    if paid_amount is not None and int(paid_amount) < expected:
        transaction.update(order_ref, {
            "status": "underpaid",
            "paidAmount": int(paid_amount),
            "paymentRef": payment_ref,
            "updatedAt": _now().isoformat(),
        })
        return {"status": "underpaid", "orderId": order.get("orderId"),
                "expected": expected, "received": int(paid_amount)}

    # Đơn đã "expired" nhưng tiền vẫn về thì vẫn cấp PRO cho người dùng
    transaction.update(order_ref, {
        "status": "paid",
        "paidAt": _now().isoformat(),
        "paidAmount": int(paid_amount) if paid_amount is not None else expected,
        "paymentRef": payment_ref,
        "paymentSource": source,
    })
    user_data = user_snap.to_dict() if user_snap.exists else {}
    grant = _apply_grant(transaction, user_ref, user_data, order.get("planType", "monthly"),
                         source=source, order_id=order.get("orderId"), amount=expected)
    return {"status": "paid", "orderId": order.get("orderId"), "grant": grant}


def mark_order_paid(uid: str, order_id: str, source: str, paid_amount=None, payment_ref=None) -> dict:
    user_ref = _user_ref(uid)
    order_ref = user_ref.collection("orders").document(order_id)
    return _mark_paid_txn(db.transaction(), order_ref, user_ref, source, paid_amount, payment_ref)


def mock_pay(uid: str, order_id: str) -> dict:
    if not config.ENABLE_MOCK_PAY:
        raise HTTPException(status_code=403, detail="Thanh toán giả lập đang tắt trên server.")
    return mark_order_paid(uid, order_id, source="mock", payment_ref=f"mock-{order_id}")


# ---------------------------------------------------------------------------
# Webhook ngân hàng / cổng thanh toán
# ---------------------------------------------------------------------------

def _normalize_bank_events(payload: dict) -> list:
    """Chuẩn hóa payload về danh sách {ref, content, amount}.

    Hỗ trợ: SePay (1 giao dịch/payload, transferType 'in'/'out'),
    Casso ({"data": [...]}) và payload tự định nghĩa {content, amount, id}.
    """
    items = payload.get("data") if isinstance(payload.get("data"), list) else [payload]
    events = []
    for item in items:
        if not isinstance(item, dict):
            continue
        if str(item.get("transferType", "in")).lower() != "in":
            continue  # bỏ qua tiền ra
        amount = item.get("transferAmount", item.get("amount"))
        try:
            amount = int(float(amount))
        except (TypeError, ValueError):
            continue
        if amount <= 0:
            continue
        content = " ".join(
            str(item.get(k, "")) for k in ("content", "description", "addInfo", "code") if item.get(k)
        )
        ref = item.get("id") or item.get("tid") or item.get("referenceCode") or item.get("reference")
        events.append({"ref": str(ref) if ref else None, "content": content, "amount": amount, "raw": item})
    return events


def handle_bank_webhook(payload: dict) -> dict:
    results = []
    for ev in _normalize_bank_events(payload):
        match = _CODE_RE.search(ev["content"].upper().replace(" ", ""))
        if not match:
            results.append({"ref": ev["ref"], "status": "ignored", "reason": "no_payment_code"})
            continue
        code = match.group(0)

        # Chống xử lý trùng khi cổng gửi lại webhook
        if ev["ref"]:
            try:
                db.collection("payment_events").document(ev["ref"]).create({
                    "code": code,
                    "amount": ev["amount"],
                    "receivedAt": _now().isoformat(),
                    "raw": ev["raw"],
                })
            except AlreadyExists:
                results.append({"ref": ev["ref"], "code": code, "status": "duplicate"})
                continue

        code_doc = db.collection("payment_codes").document(code).get()
        if not code_doc.exists:
            logger.warning(f"Webhook: payment code {code} not found")
            results.append({"ref": ev["ref"], "code": code, "status": "unknown_code"})
            continue

        info = code_doc.to_dict()
        try:
            res = mark_order_paid(info["uid"], info["orderId"], source="bank_transfer",
                                  paid_amount=ev["amount"], payment_ref=ev["ref"])
            results.append({"ref": ev["ref"], "code": code, **{k: res[k] for k in ("status",) if k in res}})
        except Exception as e:
            # Xóa dấu đã xử lý để lần gửi lại của cổng thanh toán được thử lại
            if ev["ref"]:
                db.collection("payment_events").document(ev["ref"]).delete()
            logger.error(f"Webhook: failed to mark order {code} paid: {e}")
            reason = e.detail if isinstance(e, HTTPException) else str(e)
            results.append({"ref": ev["ref"], "code": code, "status": "error", "reason": reason})

    return {"success": True, "results": results}

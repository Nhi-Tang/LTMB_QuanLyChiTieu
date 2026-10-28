"""Quên mật khẩu bằng mã OTP gửi qua email.

Luồng: request_code (gửi mã 6 số) -> verify_code (đổi mã lấy resetToken) -> reset_password (đặt mật khẩu mới).
Mã và token chỉ lưu dạng băm trong `password_resets/{sha256(email)}`; firestore.rules không mở collection này
nên chỉ backend (Admin SDK) đọc được.
"""
from datetime import datetime, timedelta, timezone
import hashlib
import hmac
import logging
import secrets

from fastapi import HTTPException
from firebase_admin import auth

import config
from services import mail_service
from services.firebase_service import db

logger = logging.getLogger("uvicorn.error")

_RESET_TOKEN_TTL_MINUTES = 10

PHONE_ACCOUNT_MESSAGE = "Tài khoản đăng ký bằng số điện thoại chưa thể đặt lại mật khẩu qua email. Vui lòng liên hệ hỗ trợ Mousey."
_EXPIRED_MESSAGE = "Mã xác nhận đã hết hạn, vui lòng gửi lại mã mới."


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _parse_dt(value):
    if not value or not isinstance(value, str):
        return None
    try:
        dt = datetime.fromisoformat(value)
    except ValueError:
        return None
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


def _hash(doc_id: str, secret: str) -> str:
    return hashlib.sha256(f"{doc_id}:{secret}".encode("utf-8")).hexdigest()


def _normalize_email(email: str) -> str:
    email = (email or "").strip().lower()
    if email.endswith("@mousey.local"):
        raise HTTPException(status_code=400, detail=PHONE_ACCOUNT_MESSAGE)
    if "@" not in email or "." not in email.split("@")[-1] or len(email) > 254:
        raise HTTPException(status_code=400, detail="Email không hợp lệ.")
    return email


def _doc(email: str):
    doc_id = hashlib.sha256(email.encode("utf-8")).hexdigest()
    return doc_id, db.collection("password_resets").document(doc_id)


# ---------------------------------------------------------------------------
# Email chứa mã
# ---------------------------------------------------------------------------

_TEMPLATES = {
    "vi": {
        "subject": "{code} là mã đặt lại mật khẩu Mousey của bạn",
        "title": "Đặt lại mật khẩu",
        "intro": "Bạn (hoặc ai đó) vừa yêu cầu đặt lại mật khẩu cho tài khoản Mousey gắn với email này. Nhập mã sau vào ứng dụng Mousey:",
        "expiry": "Mã có hiệu lực trong {minutes} phút.",
        "ignore": "Nếu bạn không yêu cầu, hãy bỏ qua email này, mật khẩu của bạn sẽ không thay đổi. Mousey không bao giờ hỏi mã này qua điện thoại, tin nhắn hay mạng xã hội.",
    },
    "en": {
        "subject": "{code} is your Mousey password reset code",
        "title": "Reset your password",
        "intro": "You (or someone else) asked to reset the password of the Mousey account linked to this email. Enter this code in the Mousey app:",
        "expiry": "The code expires in {minutes} minutes.",
        "ignore": "If you didn't ask for this, just ignore this email and your password will stay the same. Mousey will never ask for this code by phone, text or social media.",
    },
}


def _build_email(code: str, lang: str):
    t = _TEMPLATES.get(lang, _TEMPLATES["vi"])
    minutes = config.RESET_CODE_TTL_MINUTES
    subject = t["subject"].format(code=code)
    expiry = t["expiry"].format(minutes=minutes)
    text = f"{t['title']}\n\n{t['intro']}\n\n{code}\n\n{expiry}\n\n{t['ignore']}\n\nMousey"
    html = f"""<!doctype html>
<html><body style="margin:0;padding:24px;background:#f4f1ea;font-family:Arial,Helvetica,sans-serif;color:#1f2430">
  <table role="presentation" width="100%" style="max-width:480px;margin:0 auto;background:#ffffff;border-radius:16px;padding:32px">
    <tr><td>
      <div style="font-size:22px;font-weight:bold;color:#1E2A5A">Mousey</div>
      <h1 style="font-size:20px;margin:24px 0 12px">{t['title']}</h1>
      <p style="font-size:15px;line-height:1.5;margin:0 0 20px">{t['intro']}</p>
      <div style="font-size:34px;font-weight:bold;letter-spacing:8px;text-align:center;background:#eef0f8;color:#1E2A5A;border-radius:12px;padding:16px 0">{code}</div>
      <p style="font-size:14px;color:#5b6070;margin:20px 0 0">{expiry}</p>
      <p style="font-size:13px;line-height:1.5;color:#8a8f9c;margin:16px 0 0">{t['ignore']}</p>
    </td></tr>
  </table>
</body></html>"""
    return subject, html, text


# ---------------------------------------------------------------------------
# Các bước
# ---------------------------------------------------------------------------

def request_code(email: str, lang: str = "vi") -> dict:
    """Gửi mã 6 số. Email chưa đăng ký cũng trả về như đã gửi để không lộ email nào có tài khoản."""
    email = _normalize_email(email)
    doc_id, ref = _doc(email)
    now = _now()

    snap = ref.get()
    data = snap.to_dict() if snap.exists else {}
    last_sent = _parse_dt(data.get("lastSentAt"))
    if last_sent and (now - last_sent).total_seconds() < config.RESET_CODE_RESEND_SECONDS:
        raise HTTPException(status_code=429, detail="Bạn vừa yêu cầu mã, vui lòng đợi một chút rồi gửi lại.")

    try:
        user = auth.get_user_by_email(email)
    except auth.UserNotFoundError:
        user = None
    if user is None or user.disabled:
        # Vẫn ghi lastSentAt để email không tồn tại cũng bị giới hạn tần suất như email thật
        ref.set({"lastSentAt": now.isoformat()})
        return {"sent": True, "resendAfterSeconds": config.RESET_CODE_RESEND_SECONDS}

    code = f"{secrets.randbelow(1_000_000):06d}"
    subject, html, text = _build_email(code, lang)
    mail_service.send_email(email, subject, html, text)

    ref.set({
        "uid": user.uid,
        "codeHash": _hash(doc_id, code),
        "codeExpiresAt": (now + timedelta(minutes=config.RESET_CODE_TTL_MINUTES)).isoformat(),
        "attempts": 0,
        "lastSentAt": now.isoformat(),
    })
    logger.info(f"Đã gửi mã đặt lại mật khẩu cho uid={user.uid}")
    return {"sent": True, "resendAfterSeconds": config.RESET_CODE_RESEND_SECONDS}


def verify_code(email: str, code: str) -> dict:
    """Kiểm tra mã; đúng thì trả resetToken dùng một lần để đặt mật khẩu mới."""
    email = _normalize_email(email)
    doc_id, ref = _doc(email)
    snap = ref.get()
    data = snap.to_dict() if snap.exists else {}

    expires = _parse_dt(data.get("codeExpiresAt"))
    if not data.get("codeHash") or not expires or expires <= _now():
        raise HTTPException(status_code=400, detail=_EXPIRED_MESSAGE)

    attempts = int(data.get("attempts", 0))
    if attempts >= config.RESET_CODE_MAX_ATTEMPTS:
        raise HTTPException(status_code=429, detail="Bạn đã nhập sai quá nhiều lần, vui lòng gửi lại mã mới.")

    if not hmac.compare_digest(data["codeHash"], _hash(doc_id, (code or "").strip())):
        ref.update({"attempts": attempts + 1})
        raise HTTPException(status_code=400, detail="Mã xác nhận không đúng.")

    reset_token = secrets.token_urlsafe(32)
    ref.update({
        "codeHash": None,
        "resetTokenHash": _hash(doc_id, reset_token),
        "resetTokenExpiresAt": (_now() + timedelta(minutes=_RESET_TOKEN_TTL_MINUTES)).isoformat(),
    })
    return {"resetToken": reset_token}


def reset_password(email: str, reset_token: str, new_password: str) -> dict:
    email = _normalize_email(email)
    if not new_password or len(new_password) < 6:
        raise HTTPException(status_code=400, detail="Mật khẩu phải có ít nhất 6 ký tự")
    if len(new_password) > 128:
        raise HTTPException(status_code=400, detail="Mật khẩu quá dài.")

    doc_id, ref = _doc(email)
    snap = ref.get()
    data = snap.to_dict() if snap.exists else {}

    expires = _parse_dt(data.get("resetTokenExpiresAt"))
    token_hash = data.get("resetTokenHash")
    if (not token_hash or not expires or expires <= _now()
            or not hmac.compare_digest(token_hash, _hash(doc_id, reset_token or ""))):
        raise HTTPException(status_code=400, detail="Phiên đặt lại mật khẩu đã hết hạn, vui lòng làm lại từ đầu.")

    uid = data["uid"]
    auth.update_user(uid, password=new_password)
    # Đăng xuất mọi thiết bị đang đăng nhập bằng mật khẩu cũ
    auth.revoke_refresh_tokens(uid)
    ref.delete()
    logger.info(f"Đã đặt lại mật khẩu cho uid={uid}")
    return {"success": True}

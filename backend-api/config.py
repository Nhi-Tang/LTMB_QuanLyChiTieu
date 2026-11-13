import os
from dotenv import load_dotenv

load_dotenv()


def _bool(name: str, default: bool = False) -> bool:
    return os.getenv(name, str(default)).strip().lower() in ("1", "true", "yes", "on")


# ---- Bảo mật / môi trường ----
# CHỈ bật khi dev offline: chấp nhận Firebase ID token mà không kiểm chữ ký. Tuyệt đối tắt khi deploy.
ALLOW_UNVERIFIED_TOKEN = _bool("ALLOW_UNVERIFIED_TOKEN", False)

# ---- Quên mật khẩu: mã OTP gửi qua email ----
# Render gói free chặn SMTP, nên gửi email qua HTTP API của Brevo (https://www.brevo.com, free 300 email/ngày).
# MAIL_FROM_EMAIL phải là địa chỉ đã xác minh trong Brevo (Senders & IP).
BREVO_API_KEY = os.getenv("BREVO_API_KEY", "").strip()
MAIL_FROM_EMAIL = os.getenv("MAIL_FROM_EMAIL", "").strip()
MAIL_FROM_NAME = os.getenv("MAIL_FROM_NAME", "Mousey").strip()
RESET_CODE_TTL_MINUTES = int(os.getenv("RESET_CODE_TTL_MINUTES", "10"))
RESET_CODE_MAX_ATTEMPTS = int(os.getenv("RESET_CODE_MAX_ATTEMPTS", "5"))
RESET_CODE_RESEND_SECONDS = int(os.getenv("RESET_CODE_RESEND_SECONDS", "60"))

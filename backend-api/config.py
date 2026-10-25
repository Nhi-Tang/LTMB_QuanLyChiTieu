import os
from dotenv import load_dotenv

load_dotenv()


def _bool(name: str, default: bool = False) -> bool:
    return os.getenv(name, str(default)).strip().lower() in ("1", "true", "yes", "on")


# ---- Bảo mật / môi trường ----
# CHỈ bật khi dev offline: chấp nhận Firebase ID token mà không kiểm chữ ký. Tuyệt đối tắt khi deploy.
ALLOW_UNVERIFIED_TOKEN = _bool("ALLOW_UNVERIFIED_TOKEN", False)
# Bật endpoint /subscription/mock-pay để test luồng thanh toán khi chưa có cổng thanh toán thật.
ENABLE_MOCK_PAY = _bool("ENABLE_MOCK_PAY", False)
ADMIN_EMAILS = {
    e.strip().lower()
    for e in os.getenv("ADMIN_EMAILS", "admin@mousey.com").split(",")
    if e.strip()
}

# ---- Giá gói PRO (VND) — phải khớp lib/core/constants/pricing.dart ----
PLAN_PRICES = {
    "monthly": int(os.getenv("PRICE_MONTHLY", "20000")),
    "yearly": int(os.getenv("PRICE_YEARLY", "200000")),
}
PLAN_DAYS = {"monthly": 30, "yearly": 365, "trial": 7}
ORDER_TTL_MINUTES = int(os.getenv("ORDER_TTL_MINUTES", "15"))

# ---- Tài khoản nhận tiền (hiển thị trên VietQR) ----
PAYMENT_BANK_ID = os.getenv("PAYMENT_BANK_ID", "MB")  # mã VietQR: MB, VCB, TCB, ... hoặc BIN 970422
PAYMENT_BANK_NAME = os.getenv("PAYMENT_BANK_NAME", "MB Bank")
PAYMENT_ACCOUNT_NO = os.getenv("PAYMENT_ACCOUNT_NO", "0912345678")
PAYMENT_ACCOUNT_NAME = os.getenv("PAYMENT_ACCOUNT_NAME", "MOUSEY APP")
# Tiền tố nội dung chuyển khoản, dùng để webhook nhận diện đơn hàng
PAYMENT_CODE_PREFIX = os.getenv("PAYMENT_CODE_PREFIX", "MSY")

# ---- Webhook cổng thanh toán (SePay / Casso / ...) ----
# Cổng gửi header "Authorization: Apikey <secret>" hoặc "X-Webhook-Secret: <secret>".
PAYMENT_WEBHOOK_SECRET = os.getenv("PAYMENT_WEBHOOK_SECRET", "")

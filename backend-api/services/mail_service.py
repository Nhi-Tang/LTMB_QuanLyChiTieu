import json
import logging
import urllib.error
import urllib.request

from fastapi import HTTPException

import config

logger = logging.getLogger("uvicorn.error")

_BREVO_URL = "https://api.brevo.com/v3/smtp/email"


def is_configured() -> bool:
    return bool(config.BREVO_API_KEY and config.MAIL_FROM_EMAIL)


def send_email(to_email: str, subject: str, html: str, text: str) -> None:
    """Gửi email qua HTTP API của Brevo (Render gói free chặn cổng SMTP)."""
    if not is_configured():
        logger.error("Chưa cấu hình BREVO_API_KEY / MAIL_FROM_EMAIL, không gửi được email")
        raise HTTPException(status_code=503, detail="Chức năng gửi email tạm thời chưa sẵn sàng, vui lòng thử lại sau.")

    body = json.dumps({
        "sender": {"name": config.MAIL_FROM_NAME, "email": config.MAIL_FROM_EMAIL},
        "to": [{"email": to_email}],
        "subject": subject,
        "htmlContent": html,
        "textContent": text,
    }).encode("utf-8")
    request = urllib.request.Request(
        _BREVO_URL,
        data=body,
        method="POST",
        headers={
            "api-key": config.BREVO_API_KEY,
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            response.read()
    except urllib.error.HTTPError as e:
        logger.error(f"Brevo trả lỗi {e.code}: {e.read().decode('utf-8', 'replace')[:500]}")
        raise HTTPException(status_code=502, detail="Không gửi được email, vui lòng thử lại sau.")
    except (urllib.error.URLError, TimeoutError) as e:
        logger.error(f"Không kết nối được Brevo: {e}")
        raise HTTPException(status_code=502, detail="Không gửi được email, vui lòng thử lại sau.")

from fastapi import APIRouter, Depends, Request, HTTPException
from datetime import datetime, timezone
from services.firebase_service import db
from services import password_reset_service
from middleware.auth import verify_firebase_token
from pydantic import BaseModel

router = APIRouter(prefix="/auth", tags=["Authentication"])

class SessionResponse(BaseModel):
    uid: str
    email: str | None = None
    displayName: str | None = None
    photoUrl: str | None = None
    provider: str
    plan: str
    proExpiredAt: str | None = None

@router.post("/session", response_model=SessionResponse)
async def create_or_update_session(request: Request, user_data: dict = Depends(verify_firebase_token)):
    uid = user_data["uid"]
    email = user_data.get("email")
    display_name = user_data.get("name") or "Người dùng"
    photo_url = user_data.get("picture")

    # Extract sign-in provider from firebase claims
    firebase_claims = user_data.get("firebase", {})
    provider = firebase_claims.get("sign_in_provider", "password")

    user_ref = db.collection("users").document(uid)
    user_doc = user_ref.get()

    now = datetime.now(timezone.utc).isoformat()

    if not user_doc.exists:
        initial_data = {
            "uid": uid,
            "email": email,
            "displayName": display_name,
            "photoUrl": photo_url,
            "provider": provider,
            "plan": "free",
            "proExpiredAt": None,
            "createdAt": now,
            "lastLoginAt": now,
        }
        user_ref.set(initial_data)
        doc_data = initial_data
    else:
        existing = user_doc.to_dict() or {}
        update_data = {
            "lastLoginAt": now,
        }
        # Doc do client tạo trước đó có thể thiếu các trường do server quản lý
        if "plan" not in existing:
            update_data["plan"] = "free"
        if "createdAt" not in existing:
            update_data["createdAt"] = now
        if display_name:
            update_data["displayName"] = display_name
        if photo_url:
            update_data["photoUrl"] = photo_url

        user_ref.update(update_data)
        doc_data = existing
        doc_data.update(update_data)

    return SessionResponse(
        uid=doc_data.get("uid") or uid,
        email=doc_data.get("email"),
        displayName=doc_data.get("displayName"),
        photoUrl=doc_data.get("photoUrl"),
        provider=doc_data.get("provider", "password"),
        plan=doc_data.get("plan", "free"),
        proExpiredAt=doc_data.get("proExpiredAt"),
    )

@router.get("/me", response_model=SessionResponse)
async def get_current_user_profile(user_data: dict = Depends(verify_firebase_token)):
    uid = user_data["uid"]
    user_ref = db.collection("users").document(uid)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise HTTPException(status_code=404, detail="Không tìm thấy thông tin người dùng")

    doc_data = user_doc.to_dict()
    return SessionResponse(
        uid=doc_data.get("uid") or uid,
        email=doc_data.get("email"),
        displayName=doc_data.get("displayName"),
        photoUrl=doc_data.get("photoUrl"),
        provider=doc_data.get("provider", "password"),
        plan=doc_data.get("plan", "free"),
        proExpiredAt=doc_data.get("proExpiredAt"),
    )


# ---- Quên mật khẩu (không cần đăng nhập): gửi mã -> xác nhận mã -> đặt mật khẩu mới ----

class ResetCodeRequest(BaseModel):
    email: str
    lang: str = "vi"

class VerifyResetCodeRequest(BaseModel):
    email: str
    code: str

class ResetPasswordRequest(BaseModel):
    email: str
    resetToken: str
    newPassword: str

# def (không async): các hàm gọi Firebase/Brevo chặn luồng, FastAPI chạy chúng trong threadpool
@router.post("/password-reset/request")
def request_password_reset_code(body: ResetCodeRequest):
    return password_reset_service.request_code(body.email, body.lang)

@router.post("/password-reset/verify")
def verify_password_reset_code(body: VerifyResetCodeRequest):
    return password_reset_service.verify_code(body.email, body.code)

@router.post("/password-reset/confirm")
def confirm_password_reset(body: ResetPasswordRequest):
    return password_reset_service.reset_password(body.email, body.resetToken, body.newPassword)

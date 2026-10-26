from fastapi import APIRouter, Depends, HTTPException
from firebase_admin import auth
from pydantic import BaseModel
from services.firebase_service import db
from middleware.auth import verify_firebase_token
import config

router = APIRouter(prefix="/admin", tags=["Admin"])


async def require_admin(user_data: dict = Depends(verify_firebase_token)):
    """Chỉ cho admin: email nằm trong ADMIN_EMAILS hoặc users/{uid}.role == 'admin'."""
    email = (user_data.get("email") or "").lower()
    if email in config.ADMIN_EMAILS:
        return user_data
    doc = db.collection("users").document(user_data["uid"]).get()
    if doc.exists and (doc.to_dict() or {}).get("role") == "admin":
        return user_data
    raise HTTPException(status_code=403, detail="Chỉ Quản trị viên mới được thực hiện thao tác này")


class ActiveRequest(BaseModel):
    active: bool


@router.post("/users/{uid}/active")
async def set_user_active(uid: str, body: ActiveRequest, admin: dict = Depends(require_admin)):
    if uid == admin["uid"]:
        raise HTTPException(status_code=400, detail="Không thể khóa tài khoản Admin đang đăng nhập!")

    # Khóa ở Firebase Auth: đăng nhập mới bị từ chối (user-disabled) và
    # thu hồi refresh token để phiên đang mở không lấy được token mới.
    try:
        auth.update_user(uid, disabled=not body.active)
        if not body.active:
            auth.revoke_refresh_tokens(uid)
    except auth.UserNotFoundError:
        raise HTTPException(status_code=404, detail="Không tìm thấy tài khoản")

    # isActive chỉ server ghi (firestore.rules); app đọc trường này để đăng xuất phiên bị khóa
    db.collection("users").document(uid).set({"isActive": body.active}, merge=True)
    return {"uid": uid, "isActive": body.active}

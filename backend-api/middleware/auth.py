from fastapi import Request, HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth
import jwt
import logging
import config

logger = logging.getLogger("uvicorn.error")
security = HTTPBearer()

async def verify_firebase_token(request: Request, credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Thiếu Authorization Bearer Token",
        )

    decoded_token = None
    try:
        decoded_token = auth.verify_id_token(token)
    except Exception as e:
        if not config.ALLOW_UNVERIFIED_TOKEN:
            logger.warning(f"verify_id_token failed: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Phiên đăng nhập không hợp lệ hoặc đã hết hạn",
            )
        # Chỉ dùng khi dev offline (ALLOW_UNVERIFIED_TOKEN=true): giải mã JWT không kiểm chữ ký
        logger.warning(f"verify_id_token failed ({str(e)}). ALLOW_UNVERIFIED_TOKEN is on, decoding without signature check")
        try:
            decoded_token = jwt.decode(token, options={"verify_signature": False})
        except Exception as jwt_err:
            logger.error(f"Token verification failed completely: {str(jwt_err)}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Lỗi xác thực Firebase: {str(e)}",
            )

    request.state.user = {
        "uid": decoded_token.get("uid") or decoded_token.get("user_id") or decoded_token.get("sub"),
        "email": decoded_token.get("email"),
        "name": decoded_token.get("name") or decoded_token.get("displayName"),
        "picture": decoded_token.get("picture") or decoded_token.get("photoURL"),
        "firebase": decoded_token.get("firebase", {})
    }
    return request.state.user

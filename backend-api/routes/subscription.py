import hmac
from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import config
from middleware.auth import verify_firebase_token
from services import subscription_service

router = APIRouter(prefix="/subscription", tags=["Subscription"])

class CreateOrderRequest(BaseModel):
    planType: str
    # Giữ để tương thích client cũ; server luôn tính giá theo planType
    amount: int | None = None

class MockPayRequest(BaseModel):
    orderId: str

@router.get("/status")
async def get_subscription_status(user_data: dict = Depends(verify_firebase_token)):
    return subscription_service.get_status(user_data["uid"])

@router.get("/plans")
async def get_plans():
    return {
        "prices": config.PLAN_PRICES,
        "days": config.PLAN_DAYS,
        "mockPayEnabled": config.ENABLE_MOCK_PAY,
    }

@router.post("/start-trial")
async def start_trial_subscription(user_data: dict = Depends(verify_firebase_token)):
    return subscription_service.start_trial(user_data["uid"])

@router.post("/create-order")
async def create_subscription_order(body: CreateOrderRequest, user_data: dict = Depends(verify_firebase_token)):
    return subscription_service.create_order(user_data["uid"], body.planType)

@router.get("/check-order/{orderId}")
async def check_subscription_order(orderId: str, user_data: dict = Depends(verify_firebase_token)):
    return subscription_service.check_order_status(user_data["uid"], orderId)

@router.post("/mock-pay")
async def mock_pay_order(body: MockPayRequest, user_data: dict = Depends(verify_firebase_token)):
    if not body.orderId:
        raise HTTPException(status_code=400, detail="Thiếu mã đơn hàng orderId")
    return subscription_service.mock_pay(user_data["uid"], body.orderId)

def _verify_webhook_secret(request: Request):
    secret = config.PAYMENT_WEBHOOK_SECRET
    if not secret:
        raise HTTPException(status_code=503, detail="Webhook thanh toán chưa được cấu hình")
    auth_header = request.headers.get("Authorization", "")
    provided = request.headers.get("X-Webhook-Secret", "")
    if auth_header.lower().startswith("apikey "):
        provided = auth_header[7:].strip()
    elif auth_header.lower().startswith("bearer "):
        provided = auth_header[7:].strip()
    if not provided or not hmac.compare_digest(provided, secret):
        raise HTTPException(status_code=401, detail="Sai webhook secret")

@router.post("/webhook/bank")
async def bank_webhook(request: Request):
    """Cổng thanh toán (SePay/Casso/...) gọi vào khi tài khoản nhận được tiền."""
    _verify_webhook_secret(request)
    payload = await request.json()
    if not isinstance(payload, dict):
        raise HTTPException(status_code=400, detail="Payload không hợp lệ")
    result = subscription_service.handle_bank_webhook(payload)
    # SePay/Casso chỉ gửi lại webhook khi nhận mã lỗi HTTP
    if any(r.get("retryable") for r in result["results"]):
        return JSONResponse(status_code=500, content={**result, "success": False})
    return result

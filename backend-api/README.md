# Mousey Backend API (FastAPI)

Backend là nơi **duy nhất** được cấp/gia hạn gói PRO. `firestore.rules` chặn app ghi các trường
`plan`, `proExpiredAt`, `trialUsed`, `role`, và chặn mọi truy cập vào `orders`, `subscriptions`.

## Chạy local

```bash
cd backend-api
pip install -r requirements.txt
cp .env.example .env          # sửa giá trị nếu cần
# đặt serviceAccountKey.json (Firebase Admin SDK) cạnh main.py, KHÔNG commit file này
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Chạy app trỏ vào backend:

```bash
# Android emulator (mặc định): http://10.0.2.2:8000
flutter run
# Điện thoại thật cùng mạng Wi-Fi với máy tính:
flutter run --dart-define=API_BASE_URL=http://<IP-máy-tính>:8000
# Bản release (bắt buộc https):
flutter build apk --dart-define=API_BASE_URL=https://api.your-domain.vn
```

Test: `python -m unittest discover -s tests -t .`

## Endpoint

| Method | Path | Mô tả |
|---|---|---|
| POST | `/auth/session` | Tạo/cập nhật `users/{uid}` (role, plan mặc định) khi đăng nhập |
| GET | `/auth/me` | Thông tin người dùng |
| GET | `/subscription/plans` | Giá gói, số ngày, mock-pay có bật không |
| GET | `/subscription/status` | Trạng thái PRO (tự hạ về free khi hết hạn) |
| POST | `/subscription/start-trial` | Dùng thử 7 ngày (1 lần/tài khoản) |
| POST | `/subscription/create-order` | `{planType}` → đơn hàng + mã chuyển khoản + `qrUrl` VietQR |
| GET | `/subscription/check-order/{orderId}` | `pending` / `paid` / `expired` / `underpaid` |
| POST | `/subscription/mock-pay` | Chỉ khi `ENABLE_MOCK_PAY=true` (dev) |
| POST | `/subscription/webhook/bank` | Cổng thanh toán báo có tiền vào |

Mọi endpoint (trừ `/subscription/plans` và webhook) cần header `Authorization: Bearer <Firebase ID token>`.

## Kết nối thanh toán thật

Luồng: app tạo đơn → người dùng quét VietQR, chuyển khoản với nội dung `MSYxxxxxxxx` →
cổng thanh toán (SePay, Casso, PayOS webhook...) theo dõi tài khoản ngân hàng và gọi
`POST /subscription/webhook/bank` → backend tìm đơn qua mã trong nội dung, kiểm tra số tiền,
đánh dấu `paid` và cấp PRO → app (đang poll mỗi 5 giây + nghe Firestore realtime) mở khóa PRO.

Các bước:
1. Đặt tài khoản nhận tiền thật trong `.env`: `PAYMENT_BANK_ID`, `PAYMENT_ACCOUNT_NO`, `PAYMENT_ACCOUNT_NAME`.
2. Deploy backend lên server có **https**.
3. Đăng ký cổng thanh toán, khai báo webhook URL `https://<domain>/subscription/webhook/bank`,
   chọn xác thực API Key và đặt cùng giá trị vào `PAYMENT_WEBHOOK_SECRET`.
   (Backend nhận `Authorization: Apikey <secret>`, `Bearer <secret>` hoặc `X-Webhook-Secret`.)
4. Đặt `ENABLE_MOCK_PAY=false`, `ALLOW_UNVERIFIED_TOKEN=false`.
5. Deploy `firestore.rules`: `firebase deploy --only firestore:rules`.

Payload đang hỗ trợ: SePay (`transferType`, `transferAmount`, `content`, `id`), Casso
(`data: [{tid, amount, description}]`), hoặc tự định nghĩa `{id, amount, content}`.
Cổng khác chỉ cần chỉnh `_normalize_bank_events` trong `services/subscription_service.py`.
Webhook chống xử lý trùng theo mã giao dịch (`payment_events/{id}`) và chuyển khoản thiếu tiền
được đánh dấu `underpaid` (không cấp PRO).

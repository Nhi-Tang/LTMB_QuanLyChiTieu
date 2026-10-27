# Mousey Backend API (FastAPI)

Backend là nơi **duy nhất** được cấp/gia hạn gói PRO. `firestore.rules` chặn app ghi các trường
`plan`, `proExpiredAt`, `trialUsed`, `isActive`, và chặn mọi truy cập vào `orders`, `subscriptions`.

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
# Mặc định (không cần tham số): server thật https://mousey-api.onrender.com
flutter run
flutter build apk --release
# Backend chạy trên máy tính, Android emulator:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
# Backend chạy trên máy tính, điện thoại thật cùng mạng Wi-Fi:
flutter run --dart-define=API_BASE_URL=http://<IP-máy-tính>:8000
```

Test: `python -m unittest discover -s tests -t .`

## Deploy lên Render

Repo đã có `render.yaml` ở thư mục gốc. Render đọc file này để tạo service `mousey-api`
(gói free, region Singapore, Python 3.12, tự deploy lại mỗi khi push lên nhánh đã chọn).

1. Đăng ký https://render.com bằng tài khoản GitHub, cho phép Render truy cập repo `LTMB_QuanLyChiTieu`.
2. **New → Blueprint** → chọn repo → chọn nhánh `main` → Render tìm thấy `render.yaml`.
3. Điền các biến bí mật Render hỏi:
   - `FIREBASE_SERVICE_ACCOUNT_JSON`: toàn bộ nội dung file `serviceAccountKey.json`.
     Trên Windows, copy nhanh: `Get-Content serviceAccountKey.json -Raw | Set-Clipboard` rồi dán.
     (Cũng nhận chuỗi base64 của file.)
   - `PAYMENT_ACCOUNT_NO`, `PAYMENT_ACCOUNT_NAME`: số và tên tài khoản nhận tiền thật.
   - `PAYMENT_WEBHOOK_SECRET`: để trống nếu chưa nối cổng thanh toán (webhook sẽ tắt), xem mục "Nối SePay".
4. **Apply**. Chờ build xong (~3 phút), mở `https://mousey-api.onrender.com/` (tên có thể khác
   nếu bị trùng, xem trên Dashboard) → thấy `{"message":"Mousey API is running successfully!"}`.
5. App mặc định đã trỏ vào `https://mousey-api.onrender.com` (`lib/core/constants/api_config.dart`).
   Nếu tên service khác, sửa `defaultValue` ở đó hoặc build với `--dart-define=API_BASE_URL=<url>`.

Lưu ý gói free:
- Server **ngủ sau 15 phút** không có request; lần gọi đầu mất ~30-60s (app đã chờ tối đa 60s).
  Muốn luôn thức: nâng gói Starter, hoặc dùng dịch vụ ping (vd. UptimeRobot) gọi `/` mỗi 10 phút.
- `ENABLE_MOCK_PAY=false` trên server: chỉ dùng thử 7 ngày và thanh toán thật (webhook) cấp được PRO.
- Không bao giờ commit `serviceAccountKey.json`/`.env`. Nếu khóa bị lộ: Firebase Console →
  Project settings → Service accounts → tạo khóa mới, xóa khóa cũ, cập nhật biến trên Render.

## Endpoint

| Method | Path | Mô tả |
|---|---|---|
| POST | `/auth/session` | Tạo/cập nhật `users/{uid}` (plan mặc định) khi đăng nhập |
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

### Nối SePay (đang dùng cho server Render)

1. **Tạo secret** (chuỗi ngẫu nhiên, giữ bí mật). PowerShell:
   ```powershell
   -join ((48..57)+(65..90)+(97..122) | Get-Random -Count 40 | % {[char]$_}) | Set-Clipboard
   ```
2. **Render** → service `mousey-api` → Environment → `PAYMENT_WEBHOOK_SECRET` = chuỗi vừa tạo → Save
   (Render tự deploy lại, ~2 phút).
3. **SePay** (https://my.sepay.vn): đăng ký, liên kết tài khoản ngân hàng nhận tiền
   (đúng số `PAYMENT_ACCOUNT_NO` trên Render).
4. SePay → **Tích hợp WebHooks → Thêm webhooks**:
   - Sự kiện: **Có tiền vào**; chọn đúng tài khoản ngân hàng.
   - URL: `https://mousey-api.onrender.com/subscription/webhook/bank`
   - Bỏ qua nếu không có code thanh toán: **Không** (backend tự tìm mã `MSY...` trong nội dung).
   - Kiểu chứng thực: **API Key** → dán cùng chuỗi secret ở bước 1.
   - Request content type: `application/json`.
5. Kiểm tra: SePay có nút gửi thử, hoặc mở app → Nâng cấp → Gói Tháng → chuyển 20.000đ
   **từ một tài khoản khác** với đúng nội dung `MSY...` → app tự lên PRO trong vài giây.
   Xem lịch sử gọi ở SePay → Nhật ký WebHooks (phản hồi `{"success": true, ...}` là đúng).

Hành vi webhook:
- Chống xử lý trùng theo mã giao dịch (`payment_events/{id}`).
- Không nhận thanh toán thiếu: mỗi giao dịch phải đủ giá gói (không cộng dồn). Chuyển thiếu → đơn `underpaid`,
  không cấp PRO, app báo "Số dư tài khoản không đủ để thực hiện thanh toán."; các lần chuyển thiếu lưu ở `underpaidTransfers` để hoàn tiền thủ công.
- Tiền về sau khi đơn hết hạn 15 phút vẫn được cấp PRO.
- Lỗi hạ tầng (Firestore...) → trả HTTP 500 để SePay tự gửi lại; lỗi nghiệp vụ (không thấy đơn) → 200.
- Webhook sai secret → 401; chưa đặt `PAYMENT_WEBHOOK_SECRET` → 503 (webhook tắt).

Payload đang hỗ trợ: SePay (`transferType`, `transferAmount`, `content`, `id`), Casso
(`data: [{tid, amount, description}]`), hoặc tự định nghĩa `{id, amount, content}`.
Cổng khác chỉ cần chỉnh `_normalize_bank_events` trong `services/subscription_service.py`.

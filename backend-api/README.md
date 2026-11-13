# Mousey Backend API (FastAPI)

Backend tạo hồ sơ người dùng khi đăng nhập và lo chức năng quên mật khẩu.
`firestore.rules` chặn app tự ghi các trường do server quản lý (`role`, `isActive`).

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

Thử API cần đăng nhập trên http://localhost:8000/docs: lấy Firebase ID token của một tài khoản
(không cần app), rồi dán vào nút **Authorize**. Token hết hạn sau 1 giờ.

```bash
python scripts/get_token.py <email>   # Windows: tự copy vào clipboard; máy khác: in ra màn hình
```

## Deploy lên Render

Repo đã có `render.yaml` ở thư mục gốc. Render đọc file này để tạo service `mousey-api`
(gói free, region Singapore, Python 3.12, tự deploy lại mỗi khi push lên nhánh đã chọn).

1. Đăng ký https://render.com bằng tài khoản GitHub, cho phép Render truy cập repo `LTMB_QuanLyChiTieu`.
2. **New → Blueprint** → chọn repo → chọn nhánh `main` → Render tìm thấy `render.yaml`.
3. Điền các biến bí mật Render hỏi:
   - `FIREBASE_SERVICE_ACCOUNT_JSON`: toàn bộ nội dung file `serviceAccountKey.json`.
     Trên Windows, copy nhanh: `Get-Content serviceAccountKey.json -Raw | Set-Clipboard` rồi dán.
     (Cũng nhận chuỗi base64 của file.)
   - `BREVO_API_KEY`, `MAIL_FROM_EMAIL`: xem mục "Quên mật khẩu" bên dưới.
4. **Apply**. Chờ build xong (~3 phút), mở `https://mousey-api.onrender.com/` (tên có thể khác
   nếu bị trùng, xem trên Dashboard) → thấy `{"message":"Mousey API is running successfully!"}`.
5. App mặc định đã trỏ vào `https://mousey-api.onrender.com` (`lib/core/constants/api_config.dart`).
   Nếu tên service khác, sửa `defaultValue` ở đó hoặc build với `--dart-define=API_BASE_URL=<url>`.

Lưu ý gói free:
- Server **ngủ sau 15 phút** không có request; lần gọi đầu mất ~30-60s (app đã chờ tối đa 60s).
  Muốn luôn thức: nâng gói Starter, hoặc dùng dịch vụ ping (vd. UptimeRobot) gọi `/` mỗi 10 phút.
- Không bao giờ commit `serviceAccountKey.json`/`.env`. Nếu khóa bị lộ: Firebase Console →
  Project settings → Service accounts → tạo khóa mới, xóa khóa cũ, cập nhật biến trên Render.

## Endpoint

| Method | Path | Mô tả |
|---|---|---|
| POST | `/auth/session` | Tạo/cập nhật `users/{uid}` khi đăng nhập |
| GET | `/auth/me` | Thông tin người dùng |
| POST | `/auth/password-reset/request` | `{email, lang}` → gửi mã 6 số qua email (60s mới được gửi lại) |
| POST | `/auth/password-reset/verify` | `{email, code}` → `resetToken` (sai 5 lần phải xin mã mới) |
| POST | `/auth/password-reset/confirm` | `{email, resetToken, newPassword}` → đổi mật khẩu Firebase, đăng xuất mọi thiết bị |

Mọi endpoint (trừ `/` và `/auth/password-reset/*`) cần header `Authorization: Bearer <Firebase ID token>`.

## Quên mật khẩu: gửi mã qua email (Brevo)

Render gói free chặn cổng SMTP, nên backend gửi email qua HTTP API của Brevo (free 300 email/ngày).
Chưa cấu hình thì app báo "Chức năng gửi email tạm thời chưa sẵn sàng".

1. Đăng ký https://www.brevo.com.
2. **Senders, Domains & Dedicated IPs → Senders → Add a sender**: nhập tên `Mousey` và địa chỉ gửi
   (vd. Gmail riêng của dự án), bấm link xác minh Brevo gửi tới địa chỉ đó.
3. **SMTP & API → API Keys → Generate a new API key**, copy key (chỉ hiện một lần).
4. Trên Render (service `mousey-api` → Environment) điền:
   - `BREVO_API_KEY`: key vừa tạo
   - `MAIL_FROM_EMAIL`: địa chỉ gửi đã xác minh ở bước 2
   - `MAIL_FROM_NAME`: `Mousey` (đã có sẵn trong `render.yaml`)
5. Thử trong app: Đăng nhập → Quên mật khẩu? → nhập email → nhận mã.

Gửi từ Gmail qua Brevo đôi khi vẫn vào Spam. Muốn chắc chắn vào hộp thư chính thì mua tên miền,
xác thực nó trong Brevo (DKIM/DMARC) và gửi từ địa chỉ như `no-reply@<tên-miền>`.

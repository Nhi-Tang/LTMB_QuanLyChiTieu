# Mousey – Quản lý chi tiêu cá nhân

Ứng dụng Flutter giúp ghi chép thu chi, đặt ngân sách, theo dõi mục tiêu tiết kiệm và tự động
ghi giao dịch từ thông báo ngân hàng. Dữ liệu lưu trên máy (SQLite) và đồng bộ lên Firebase.
Gói PRO được cấp qua backend FastAPI, thanh toán bằng VietQR.

## Tính năng

- **Thu chi & sổ sách**: thêm thu nhập / chi tiêu / chuyển tiền bằng bàn phím máy tính, ghi chú,
  chọn ngày. Có nhiều sổ sách, mỗi sổ tách dữ liệu riêng.
- **Danh mục**: danh mục thu/chi có icon, thêm/sửa/xoá, gợi ý danh mục theo nội dung.
- **Ngân sách**: đặt hạn mức theo danh mục, cảnh báo khi sắp vượt hoặc đã vượt.
- **Tiết kiệm**: tạo mục tiêu, nạp/rút tiền, theo dõi tiến độ.
- **Báo cáo**: biểu đồ chi tiêu theo danh mục, xu hướng 3–24 tháng, lọc theo khoảng thời gian.
- **Xuất dữ liệu**: Excel và CSV, chia sẻ qua các app khác.
- **Thông báo ngân hàng (Android)**: đọc thông báo biến động số dư của MB Bank, MoMo, ZaloPay
  và các ngân hàng khác, tạo giao dịch chờ duyệt.
- **Nhắc nhở**: nhắc ghi chép hằng ngày, trung tâm thông báo trong app.
- **Tài khoản**: đăng nhập email/mật khẩu hoặc Google, quên mật khẩu, đồng bộ nhiều thiết bị.
- **PRO**: dùng thử 7 ngày, gói tháng/năm, thanh toán VietQR, tự mở khoá khi tiền về.
- **Giao diện**: chế độ sáng/tối/theo hệ thống; 5 ngôn ngữ (Tiếng Việt, English, 日本語, 中文, 한국어).

## Công nghệ

| Phần | Công nghệ |
|---|---|
| App | Flutter (Dart SDK ^3.13), Material |
| Lưu trữ trên máy | `sqflite`, `shared_preferences` |
| Đăng nhập & đồng bộ | Firebase Auth, Cloud Firestore, Realtime Database, Google Sign-In |
| Thông báo | `flutter_local_notifications`, `NotificationListenerService` (Android) |
| Backend | FastAPI (Python 3.12), Firebase Admin SDK, deploy trên Render |
| Thanh toán | VietQR + webhook SePay |

## Cấu trúc thư mục

```
lib/
  main.dart
  firebase_options.dart
  backend/            # dữ liệu & nghiệp vụ
    database/         #   SQLite (db_helper)
    models/           #   giao dịch, ngân sách, tiết kiệm, người dùng...
    services/         #   auth, đồng bộ, báo cáo, ngân sách, PRO, xuất file...
      bank_parser/    #   đọc thông báo ngân hàng (MB, MoMo, ZaloPay, chung)
  core/               # hằng số, tiện ích, widget dùng chung
  frontend/
    screens/          # các màn hình chính (trang chủ, báo cáo, tiết kiệm, cá nhân...)
    widgets/          # bottom sheet, dialog, form...
    theme/            # màu & theme sáng/tối
    utils/            # ngôn ngữ, bản dịch
assets/               # avatar, icon
backend-api/          # backend FastAPI (xem backend-api/README.md)
test/                 # unit test & widget test
firestore.rules       # quy tắc bảo mật Firestore
render.yaml           # cấu hình deploy backend lên Render
```

## Chạy app

Yêu cầu: Flutter stable (đã thử với 3.47), Android SDK (minSdk 23), một máy ảo hoặc điện thoại Android.

```bash
flutter pub get
flutter run
```

App mặc định gọi backend thật tại `https://mousey-api.onrender.com`. Gói free của Render ngủ sau
15 phút không có request, nên lần gọi đầu có thể mất 30–60 giây.

Để trỏ vào backend chạy trên máy tính:

```bash
# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
# Điện thoại thật cùng Wi-Fi
flutter run --dart-define=API_BASE_URL=http://<IP-máy-tính>:8000
```

Build APK:

```bash
flutter build apk --release
```

### Firebase

Project Firebase: `quan-ly-chi-65a86`. Các file cấu hình `android/app/google-services.json` và
`lib/firebase_options.dart` đã có trong repo. Nếu dùng project Firebase khác, chạy
`flutterfire configure` để tạo lại hai file này, rồi deploy quy tắc:

```bash
firebase deploy --only firestore:rules
```

Đăng nhập Google cần thêm SHA-1 của keystore vào Firebase Console (Project settings → Android app).

### Đọc thông báo ngân hàng

Tính năng chỉ chạy trên Android. Lần đầu bật, app hướng dẫn cấp quyền **Truy cập thông báo**
trong Cài đặt của điện thoại.

## Backend

Backend FastAPI nằm trong `backend-api/`. Đây là nơi duy nhất được cấp gói PRO;
`firestore.rules` chặn app tự ghi các trường này. Hướng dẫn chạy local, deploy Render, danh sách
endpoint và cách nối SePay: [backend-api/README.md](backend-api/README.md).

Không commit `serviceAccountKey.json` hay `.env`.

## Kiểm thử

```bash
flutter analyze
flutter test
```

Test backend:

```bash
cd backend-api
python -m unittest discover -s tests -t .
```

## Quy ước branch

- `main`: bản ổn định.
- `dev`: gom các thay đổi trước khi đưa lên `main`.
- `feature/<tên>`, `fix/<tên>`, `style/<tên>`, `chore/<tên>`: tạo từ `dev`, xong thì merge vào `dev`.
- Các branch cũ đặt theo ngày (`NN_10`) được giữ lại dưới dạng tag `archive/NN_10`.

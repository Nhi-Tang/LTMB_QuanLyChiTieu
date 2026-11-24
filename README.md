# Mousey – Quản lý chi tiêu cá nhân

Ứng dụng Flutter giúp ghi chép thu chi, đặt ngân sách, theo dõi mục tiêu tiết kiệm và tự động
ghi giao dịch từ thông báo ngân hàng. App chạy hoàn toàn offline, không cần tài khoản: mọi dữ liệu
lưu trên máy (SQLite). Gỡ app là mất dữ liệu, nên dùng chức năng xuất Excel/CSV để sao lưu.
Mọi chức năng đều miễn phí.

## Tính năng

- **Thu chi và sổ sách**: thêm thu nhập / chi tiêu / chuyển tiền bằng bàn phím máy tính, ghi chú,
  chọn ngày. Có nhiều sổ sách, mỗi sổ tách dữ liệu riêng.
- **Danh mục**: danh mục thu/chi có icon, thêm/sửa/xoá, gợi ý danh mục theo nội dung.
- **Ngân sách**: đặt hạn mức theo danh mục, cảnh báo khi sắp vượt hoặc đã vượt.
- **Tiết kiệm**: tạo mục tiêu, nạp/rút tiền, theo dõi tiến độ.
- **Báo cáo**: biểu đồ chi tiêu theo danh mục, xu hướng 3–24 tháng, lọc theo khoảng thời gian.
- **Xuất dữ liệu**: Excel và CSV, chia sẻ qua các app khác.
- **Thông báo ngân hàng (Android)**: đọc thông báo biến động số dư của MB Bank, MoMo, ZaloPay
  và các ngân hàng khác, tạo giao dịch chờ duyệt.
- **Nhắc nhở**: nhắc ghi chép hằng ngày, trung tâm thông báo trong app.
- **Hồ sơ**: đặt tên và ảnh đại diện, lưu trên máy.
- **Giao diện**: chế độ sáng/tối/theo hệ thống; 5 ngôn ngữ (Tiếng Việt, English, 日本語, 中文, 한국어).

## Công nghệ

| Phần | Công nghệ |
|---|---|
| App | Flutter (Dart SDK ^3.13), Material |
| Lưu trữ trên máy | `sqflite`, `shared_preferences` |
| Thông báo | `flutter_local_notifications`, `NotificationListenerService` (Android) |

## Cấu trúc thư mục

```
lib/
  main.dart
  backend/            # dữ liệu & nghiệp vụ
    database/         #   SQLite (db_helper)
    models/           #   giao dịch, ngân sách, tiết kiệm, hồ sơ...
    services/         #   báo cáo, ngân sách, xuất file, thông báo...
      bank_parser/    #   đọc thông báo ngân hàng (MB, MoMo, ZaloPay, chung)
  core/               # tiện ích, widget dùng chung
  frontend/
    screens/          # các màn hình chính (trang chủ, báo cáo, tiết kiệm, cá nhân...)
    widgets/          # bottom sheet, dialog, form...
    theme/            # màu & theme sáng/tối
    utils/            # ngôn ngữ, bản dịch
assets/               # avatar, icon
test/                 # unit test & widget test
```

## Chạy app

Yêu cầu: Flutter stable (đã thử với 3.47), Android SDK (minSdk 23), một máy ảo hoặc điện thoại Android.

```bash
flutter pub get
flutter run
```

Build APK:

```bash
flutter build apk --release
```

### Đọc thông báo ngân hàng

Tính năng chỉ chạy trên Android. Lần đầu bật, app hướng dẫn cấp quyền **Truy cập thông báo**
trong Cài đặt của điện thoại.

## Kiểm thử

```bash
flutter analyze
flutter test
```

## Quy ước branch

- `main`: bản ổn định.
- `dev`: gom các thay đổi trước khi đưa lên `main`.
- `feature/<tên>`, `fix/<tên>`, `style/<tên>`, `chore/<tên>`: tạo từ `dev`, xong thì merge vào `dev`.
- Các branch cũ đặt theo ngày (`NN_10`) được giữ lại dưới dạng tag `archive/NN_10`.

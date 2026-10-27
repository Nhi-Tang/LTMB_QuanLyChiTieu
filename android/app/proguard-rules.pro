# Keep NotificationListenerService and MainActivity for release builds
-keep class com.mousey.app.BankNotificationService { *; }
-keep class com.mousey.app.MainActivity { *; }
-keep class com.mousey.app.BuildConfig { *; }

# ML Kit: plugin tham chiếu bộ nhận dạng chữ Trung/Devanagari/Nhật/Hàn, app chỉ dùng chữ Latin
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

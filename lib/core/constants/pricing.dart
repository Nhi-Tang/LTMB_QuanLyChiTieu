/// Định nghĩa các hằng số giá cước và thời gian dùng thử cho tính năng PRO của Mousey
class PricingConstants {
  /// Bật/tắt gói PRO (nâng cấp, thanh toán VietQR).
  /// false: mọi tài khoản dùng miễn phí toàn bộ tính năng và ẩn hết phần nâng cấp
  /// (dùng cho giai đoạn test trên Google Play). Đổi thành true để bán gói PRO trở lại.
  static const bool proEnabled = false;

  /// Giá gói tháng (VND)
  static const int monthlyPrice = 20000;

  /// Giá gói năm (VND)
  static const int yearlyPrice = 200000;

  /// Phần trăm tiết kiệm khi mua gói năm (%)
  static const int yearlyDiscountPercentage = 17;

  /// Số ngày dùng thử miễn phí
  static const int trialDays = 7;
}

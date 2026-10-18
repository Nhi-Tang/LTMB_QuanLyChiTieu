/// Model đại diện cho thông báo nội bộ trong ứng dụng Mousey.
class AppNotificationModel {
  final String id; // UUID định danh duy nhất thông báo
  final String? uid; // UID người dùng sở hữu thông báo
  final String type; // Loai thông báo: 'pending_tx' | 'budget' | 'pro' | 'savings' | 'sync'
  final String title; // Tiêu đề thông báo
  final String body; // Nội dung chi tiết thông báo
  final String? payload; // Dữ liệu đính kèm (JSON string hoặc tham số điều hướng)
  final String createdAt; // Thời gian tạo (định dạng ISO 8601)
  final bool isRead; // Trạng thái đã đọc (true) hay chưa đọc (false)
  final String? dedupeKey; // Khóa chống trùng lặp thông báo

  AppNotificationModel({
    required this.id,
    this.uid,
    required this.type,
    required this.title,
    required this.body,
    this.payload,
    required this.createdAt,
    this.isRead = false,
    this.dedupeKey,
  });

  /// Chuyển đổi đối tượng Model sang Map dữ liệu lưu SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'type': type,
      'title': title,
      'body': body,
      'payload': payload,
      'createdAt': createdAt,
      'isRead': isRead ? 1 : 0,
      'dedupeKey': dedupeKey,
    };
  }

  /// Khởi tạo đối tượng Model từ Map lấy từ cơ sở dữ liệu
  factory AppNotificationModel.fromMap(Map<String, dynamic> map) {
    return AppNotificationModel(
      id: map['id'] as String? ?? '',
      uid: map['uid'] as String?,
      type: map['type'] as String? ?? 'sync',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      payload: map['payload'] as String?,
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      isRead: (map['isRead'] as int? ?? 0) == 1,
      dedupeKey: map['dedupeKey'] as String?,
    );
  }

  /// Tạo bản sao đối tượng với các thông số cập nhật
  AppNotificationModel copyWith({
    String? id,
    String? uid,
    String? type,
    String? title,
    String? body,
    String? payload,
    String? createdAt,
    bool? isRead,
    String? dedupeKey,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      dedupeKey: dedupeKey ?? this.dedupeKey,
    );
  }
}

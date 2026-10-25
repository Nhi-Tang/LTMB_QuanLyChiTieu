import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/db_helper.dart';
import '../models/app_notification_model.dart';

/// Dịch vụ quản lý thông báo nội bộ trong ứng dụng (In-App Notification Service).
/// Singleton kế thừa từ [ChangeNotifier] để thông báo thời gian thực cho UI.
class InAppNotificationService extends ChangeNotifier {
  static final InAppNotificationService instance = InAppNotificationService._init();
  InAppNotificationService._init();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const _uuid = Uuid();

  /// Lấy danh sách tất cả thông báo trong ứng dụng cho người dùng
  Future<List<AppNotificationModel>> getNotifications({String? uid}) async {
    final list = await _dbHelper.getNotifications(uid: uid);
    return list;
  }

  /// Lấy số lượng thông báo chưa đọc
  Future<int> getUnreadCount({String? uid}) async {
    return await _dbHelper.getUnreadNotificationCount(uid: uid);
  }

  /// Thêm thông báo mới với cơ chế chống trùng lặp qua `dedupeKey` và tự động cắt tỉa bản ghi cũ
  Future<AppNotificationModel?> add({
    required String type,
    required String title,
    required String body,
    String? payload,
    String? dedupeKey,
    String? uid,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final newNotif = AppNotificationModel(
      id: _uuid.v4(),
      uid: uid,
      type: type,
      title: title,
      body: body,
      payload: payload,
      createdAt: nowIso,
      isRead: false,
      dedupeKey: dedupeKey,
    );

    final inserted = await _dbHelper.insertAppNotification(newNotif, uid: uid);
    if (!inserted) {
      // Thông báo bị trùng lặp dedupeKey
      return null;
    }

    // Tự động dọn dẹp các thông báo cũ hơn 30 ngày và giới hạn tối đa 200 bản ghi
    await autoPrune(uid: uid);

    notifyListeners();
    return newNotif;
  }

  /// Đánh dấu một thông báo là đã đọc
  Future<void> markRead(String id, {String? uid}) async {
    await _dbHelper.markNotificationRead(id, uid: uid);
    notifyListeners();
  }

  /// Đánh dấu tất cả thông báo của người dùng là đã đọc
  Future<void> markAllRead({String? uid}) async {
    await _dbHelper.markAllNotificationsRead(uid: uid);
    notifyListeners();
  }

  /// Xóa một thông báo theo ID
  Future<void> delete(String id, {String? uid}) async {
    await _dbHelper.deleteNotification(id, uid: uid);
    notifyListeners();
  }

  /// Xóa toàn bộ thông báo của người dùng
  Future<void> clearAll({String? uid}) async {
    await _dbHelper.clearAllNotifications(uid: uid);
    notifyListeners();
  }

  /// Tự động loại bỏ thông báo cũ hơn 30 ngày và duy trì tối đa 200 thông báo gần nhất
  Future<void> autoPrune({String? uid}) async {
    await _dbHelper.autoPruneNotifications(uid: uid);
  }

  /// Phát tín hiệu cập nhật giao diện người dùng
  void notifyUpdated() {
    notifyListeners();
  }
}

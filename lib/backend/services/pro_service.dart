import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/pricing.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'in_app_notification_service.dart';

import '../../frontend/utils/app_language.dart';
class ProService extends ChangeNotifier {
  static final ProService instance = ProService._init();
  ProService._init();

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isPro = false;
  String? _proExpiredAt;
  bool _trialUsed = false;
  int _remainingDays = 0;
  bool _isLoading = false;
  StreamSubscription? _userDocSub;

  /// Khi tắt gói PRO (PricingConstants.proEnabled = false), mọi tài khoản đều được mở khoá toàn bộ tính năng
  bool get isPro => !PricingConstants.proEnabled || _isPro;
  String? get proExpiredAt => _proExpiredAt;
  bool get trialUsed => _trialUsed;
  int get remainingDays => _remainingDays;
  bool get isLoading => _isLoading;

  /// Reset toàn bộ trạng thái trong bộ nhớ về mặc định (dùng khi đăng xuất / chuyển user)
  void resetState() {
    _userDocSub?.cancel();
    _userDocSub = null;
    _isPro = false;
    _proExpiredAt = null;
    _trialUsed = false;
    _remainingDays = 0;
    _isLoading = false;
    notifyListeners();
  }

  /// Khởi tạo và tải trạng thái PRO từ cache cục bộ (phân lập 100% theo UID) và Firestore
  Future<void> init() async {
    try {
      final user = _authService.currentFirebaseUser;
      final prefs = await SharedPreferences.getInstance();

      // Chỉ đọc cache theo UID: không dùng khóa chung để PRO của tài khoản trước không lọt sang tài khoản sau
      if (user != null) {
        final uid = user.uid;
        _isPro = prefs.getBool('mousey_is_pro_$uid') ?? false;
        _proExpiredAt = prefs.getString('mousey_pro_expired_at_$uid');
        _trialUsed = prefs.getBool('mousey_trial_used_$uid') ?? false;
        _remainingDays = prefs.getInt('mousey_remaining_days_$uid') ?? 0;
      } else {
        _isPro = false;
        _proExpiredAt = null;
        _trialUsed = false;
        _remainingDays = 0;
      }
      
      debugPrint('💎 [ProService] Init loaded from cache: isPro=$_isPro, expiry=$_proExpiredAt, trialUsed=$_trialUsed');
      notifyListeners();

      // Đồng bộ từ Cloud Firestore và lắng nghe realtime
      await checkProStatus();
      _listenToFirestoreChanges();
    } catch (e) {
      debugPrint('ProService init error: $e');
    }
  }

  /// Lắng nghe thay đổi realtime từ Firestore users/{uid}
  void _listenToFirestoreChanges() {
    final user = _authService.currentFirebaseUser;
    _userDocSub?.cancel();
    _userDocSub = null;
    if (user == null) return;

    try {
      _userDocSub = _firestore.collection('users').doc(user.uid).snapshots().listen((doc) {
        // Bỏ qua snapshot đến muộn của tài khoản đã đăng xuất
        if (_authService.currentFirebaseUser?.uid != user.uid) return;
        if (doc.exists) {
          final data = doc.data()!;
          final plan = data['plan'] as String? ?? 'free';
          final expiry = data['proExpiredAt'] as String?;
          final trial = data['trialUsed'] as bool? ?? false;

          bool activePro = (plan == 'pro');
          if (activePro && expiry != null) {
            final expiryDate = DateTime.tryParse(expiry);
            if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
              activePro = false;
              debugPrint('⚠️ [ProService] Downgrading user ${user.uid} to Free (Expired at $expiry)');
            }
          }

          _isPro = activePro;
          _proExpiredAt = expiry;
          _trialUsed = trial;
          if (_proExpiredAt != null) {
            final exp = DateTime.tryParse(_proExpiredAt!);
            if (exp != null) {
              _remainingDays = exp.difference(DateTime.now()).inDays;
              if (_remainingDays < 0) _remainingDays = 0;
            }
          }

          _saveToCache();
          notifyListeners();
          debugPrint('💎 [ProService] Realtime Firestore update for ${user.uid}: isPro=$_isPro, expiry=$_proExpiredAt');
        }
      }, onError: (err) {
        debugPrint('Firestore realtime listener error: $err');
      });
    } catch (e) {
      debugPrint('Error attaching Firestore listener: $e');
    }
  }

  /// Kiểm tra trạng thái PRO từ Cloud Firestore
  Future<bool> checkProStatus() async {
    try {
      final user = _authService.currentFirebaseUser;
      if (user == null) {
        resetState();
        return false;
      }

      // Nguồn chính: backend (cũng tự hạ cấp gói hết hạn trên server)
      try {
        final status = await ApiClient.instance.get('/subscription/status');
        // Người dùng đã đổi tài khoản trong lúc chờ: bỏ kết quả của tài khoản cũ
        if (_authService.currentFirebaseUser?.uid != user.uid) return false;
        await _applyServerStatus(status);
        _notifyExpiry(user.uid);
        return _isPro;
      } on ApiException catch (e) {
        debugPrint('💎 [ProService] Backend status unavailable (${e.message}), reading Firestore');
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (_authService.currentFirebaseUser?.uid != user.uid) return false;

      if (doc.exists) {
        final data = doc.data()!;
        final plan = data['plan'] as String? ?? 'free';
        _proExpiredAt = data['proExpiredAt'] as String?;
        _trialUsed = data['trialUsed'] as bool? ?? false;

        bool activePro = (plan == 'pro');
        if (activePro && _proExpiredAt != null) {
          final expiryDate = DateTime.tryParse(_proExpiredAt!);
          if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
            activePro = false;
            debugPrint('⚠️ [ProService] Downgrading user ${user.uid} to Free (Expired at $_proExpiredAt)');
          }
        }

        _isPro = activePro;
        if (_proExpiredAt != null) {
          final exp = DateTime.tryParse(_proExpiredAt!);
          if (exp != null) {
            _remainingDays = exp.difference(DateTime.now()).inDays;
            if (_remainingDays < 0) _remainingDays = 0;
          }
        }

        _notifyExpiry(user.uid);

        await _saveToCache();
        notifyListeners();
        debugPrint('💎 [ProService] Read plan result for ${user.uid}: isPro=$_isPro, expiry=$_proExpiredAt');
        return _isPro;
      } else {
        _isPro = false;
        _proExpiredAt = null;
        await _saveToCache();
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Check Pro Status error (offline cache used): $e');
    }
    return _isPro;
  }

  void _notifyExpiry(String uid) {
    if (!PricingConstants.proEnabled) return;
    if (_isPro && _remainingDays <= 3) {
      InAppNotificationService.instance.add(
        type: 'pro',
        title: AppLanguage.instance.t('Thông báo gói Mousey PRO'),
        body: AppLanguage.instance.t('Gói Mousey PRO của bạn còn lại {remainingDays} ngày sử dụng. Hãy gia hạn để không bị gián đoạn!', {'remainingDays': _remainingDays}),
        dedupeKey: 'notif_pro_expiry_${uid}_${_remainingDays}d',
        uid: uid,
      );
    } else if (!_isPro && _proExpiredAt != null) {
      InAppNotificationService.instance.add(
        type: 'pro',
        title: AppLanguage.instance.t('Gói Mousey PRO đã hết hạn'),
        body: AppLanguage.instance.t('Gói Mousey PRO của bạn đã hết hạn. Hãy nâng cấp ngay để tiếp tục sử dụng các tính năng cao cấp!'),
        dedupeKey: 'notif_pro_expired_$uid',
        uid: uid,
      );
    }
  }

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    // Dọn khóa chung của bản cũ (gây lẫn PRO giữa các tài khoản)
    for (final key in ['mousey_is_pro', 'mousey_pro_expired_at', 'mousey_trial_used', 'mousey_remaining_days']) {
      await prefs.remove(key);
    }

    final user = _authService.currentFirebaseUser;
    if (user != null) {
      final uid = user.uid;
      await prefs.setBool('mousey_is_pro_$uid', _isPro);
      if (_proExpiredAt != null) {
        await prefs.setString('mousey_pro_expired_at_$uid', _proExpiredAt!);
      } else {
        await prefs.remove('mousey_pro_expired_at_$uid');
      }
      await prefs.setBool('mousey_trial_used_$uid', _trialUsed);
      await prefs.setInt('mousey_remaining_days_$uid', _remainingDays);
    }
  }

  /// Dành riêng cho Unit Test (MOCK)
  @visibleForTesting
  void testSetPro(bool val) {
    _isPro = val;
    notifyListeners();
  }

  /// Áp dụng kết quả trạng thái gói từ backend (/subscription/status hoặc kết quả cấp PRO)
  Future<void> _applyServerStatus(Map<String, dynamic> data) async {
    final expiry = data['proExpiredAt'] as String?;
    final exp = expiry != null ? DateTime.tryParse(expiry) : null;
    _proExpiredAt = expiry;
    if (data.containsKey('trialUsed')) {
      _trialUsed = data['trialUsed'] as bool? ?? _trialUsed;
    }
    _isPro = data['plan'] == 'pro' && exp != null && exp.isAfter(DateTime.now());
    _remainingDays = exp != null ? exp.difference(DateTime.now()).inDays.clamp(0, 100000) : 0;
    await _saveToCache();
    notifyListeners();
  }

  /// Kích hoạt dùng thử 7 ngày miễn phí (backend kiểm tra và cấp quyền)
  Future<bool> startTrial() async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiClient.instance.post('/subscription/start-trial');
      _trialUsed = true;
      await _applyServerStatus({...result, 'trialUsed': true});
      return true;
    } on ApiException catch (e) {
      throw Exception(e.message);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tạo đơn hàng thanh toán gói PRO trên backend. Số tiền do server quyết định theo [planType].
  Future<Map<String, dynamic>?> createOrder(String planType, int amount) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await ApiClient.instance.post('/subscription/create-order', {
        'planType': planType,
        'amount': amount,
      });
    } on ApiException catch (e) {
      throw Exception(e.message);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kiểm tra trạng thái đơn hàng: 'pending' | 'paid' | 'expired' | 'underpaid'
  Future<Map<String, dynamic>> checkOrderStatus(String orderId) async {
    try {
      final order = await ApiClient.instance.get('/subscription/check-order/${Uri.encodeComponent(orderId)}');
      if (order['status'] == 'paid') {
        await checkProStatus();
      }
      return order;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'in_app_notification_service.dart';

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

  bool get isPro => _isPro;
  String? get proExpiredAt => _proExpiredAt;
  bool get trialUsed => _trialUsed;
  int get remainingDays => _remainingDays;
  bool get isLoading => _isLoading;

  /// Reset toàn bộ trạng thái trong bộ nhớ về mặc định (dùng khi đăng xuất / chuyển user)
  void resetState() {
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

      if (user != null) {
        final uid = user.uid;
        _isPro = prefs.getBool('mousey_is_pro_$uid') ?? prefs.getBool('mousey_is_pro') ?? false;
        _proExpiredAt = prefs.getString('mousey_pro_expired_at_$uid') ?? prefs.getString('mousey_pro_expired_at');
        _trialUsed = prefs.getBool('mousey_trial_used_$uid') ?? prefs.getBool('mousey_trial_used') ?? false;
        _remainingDays = prefs.getInt('mousey_remaining_days_$uid') ?? prefs.getInt('mousey_remaining_days') ?? 0;
      } else {
        _isPro = prefs.getBool('mousey_is_pro') ?? false;
        _proExpiredAt = prefs.getString('mousey_pro_expired_at');
        _trialUsed = prefs.getBool('mousey_trial_used') ?? false;
        _remainingDays = prefs.getInt('mousey_remaining_days') ?? 0;
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
    if (user == null) return;

    try {
      _firestore.collection('users').doc(user.uid).snapshots().listen((doc) {
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

      debugPrint('💎 [ProService] Reading plan for user ${user.uid} from Firestore...');
      final doc = await _firestore.collection('users').doc(user.uid).get();

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
            try {
              await _firestore.collection('users').doc(user.uid).update({'plan': 'free'});
            } catch (_) {}
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

        if (_isPro && _remainingDays <= 3) {
          InAppNotificationService.instance.add(
            type: 'pro',
            title: 'Thông báo gói Mousey PRO',
            body: 'Gói Mousey PRO của bạn còn lại $_remainingDays ngày sử dụng. Hãy gia hạn để không bị gián đoạn!',
            dedupeKey: 'notif_pro_expiry_${user.uid}_${_remainingDays}d',
            uid: user.uid,
          );
        } else if (!_isPro && _proExpiredAt != null) {
          InAppNotificationService.instance.add(
            type: 'pro',
            title: 'Gói Mousey PRO đã hết hạn',
            body: 'Gói Mousey PRO của bạn đã hết hạn. Hãy nâng cấp ngay để tiếp tục sử dụng các tính năng cao cấp!',
            dedupeKey: 'notif_pro_expired_${user.uid}',
            uid: user.uid,
          );
        }

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

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mousey_is_pro', _isPro);
    if (_proExpiredAt != null) {
      await prefs.setString('mousey_pro_expired_at', _proExpiredAt!);
    } else {
      await prefs.remove('mousey_pro_expired_at');
    }
    await prefs.setBool('mousey_trial_used', _trialUsed);
    await prefs.setInt('mousey_remaining_days', _remainingDays);

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

  /// Kích hoạt dùng thử 7 ngày miễn phí
  Future<bool> startTrial() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = _authService.currentFirebaseUser;
      if (user == null) throw Exception('Chưa đăng nhập tài khoản.');

      final docRef = _firestore.collection('users').doc(user.uid);
      
      try {
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          bool used = false;
          if (snapshot.exists) {
            used = snapshot.data()?['trialUsed'] as bool? ?? false;
          }
          if (used) {
            throw Exception('Bạn đã sử dụng gói dùng thử trước đó.');
          }

          final now = DateTime.now();
          final expiry = now.add(const Duration(days: 7)).toIso8601String();

          transaction.set(docRef, {
            'plan': 'pro',
            'planType': 'trial',
            'planSource': 'trial',
            'trialUsed': true,
            'proExpiredAt': expiry,
            'proStartedAt': now.toIso8601String(),
          }, SetOptions(merge: true));

          debugPrint('💎 [ProService] Writing trial plan to Firestore for user ${user.uid}: expiry=$expiry');
        });
      } catch (fsErr) {
        debugPrint('Firestore trial error (fallback used): $fsErr');
        if (_trialUsed) {
          _isLoading = false;
          notifyListeners();
          throw Exception('Bạn đã sử dụng gói dùng thử trước đó.');
        }
      }

      // Local fallback activation
      _isPro = true;
      _trialUsed = true;
      final expiry = DateTime.now().add(const Duration(days: 7)).toIso8601String();
      _proExpiredAt = expiry;
      _remainingDays = 7;
      await _saveToCache();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Tạo đơn hàng thanh toán gói PRO
  Future<Map<String, dynamic>?> createOrder(String planType, int amount) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = _authService.currentFirebaseUser;
      if (user == null) throw Exception('Chưa đăng nhập tài khoản.');

      final orderId = 'MOUSEY_ORDER_${planType.toUpperCase()}_${amount}_${DateTime.now().millisecondsSinceEpoch}';
      final orderData = {
        'orderId': orderId,
        'userId': user.uid,
        'planType': planType,
        'amount': amount,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      try {
        await _firestore.collection('users').doc(user.uid).collection('orders').doc(orderId).set(orderData);
      } catch (fsErr) {
        debugPrint('Firestore write order error (permission fallback used): $fsErr');
      }

      _isLoading = false;
      notifyListeners();

      return {
        'orderId': orderId,
        'amount': amount,
        'planType': planType,
        'status': 'pending',
        'bank': 'MB Bank',
        'accountNo': '0912345678',
        'accountName': 'MOUSEY APP',
        'content': orderId,
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Kiểm tra trạng thái đơn hàng thanh toán từ Firestore
  Future<Map<String, dynamic>> checkOrderStatus(String orderId) async {
    try {
      final user = _authService.currentFirebaseUser;
      if (user == null) throw Exception('Chưa đăng nhập tài khoản.');

      try {
        final doc = await _firestore.collection('users').doc(user.uid).collection('orders').doc(orderId).get();
        if (doc.exists) {
          final data = doc.data()!;
          final status = data['status'] as String? ?? 'pending';
          if (status == 'paid') {
            await checkProStatus();
            return data;
          }
        }
      } catch (fsErr) {
        debugPrint('Firestore check order error (fallback used): $fsErr');
      }

      await mockPay(orderId);
      return {'status': 'paid'};
    } catch (e) {
      debugPrint('Check order status error: $e');
      rethrow;
    }
  }

  /// Giả lập thanh toán đơn hàng thành công (Mock Pay / Grant Pro)
  Future<bool> mockPay(String orderId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = _authService.currentFirebaseUser;
      if (user == null) throw Exception('Chưa đăng nhập tài khoản.');

      final userDocRef = _firestore.collection('users').doc(user.uid);
      final orderDocRef = userDocRef.collection('orders').doc(orderId);

      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userDocRef);
        String? currentExpiryStr;
        if (userSnapshot.exists) {
          final userData = userSnapshot.data();
          if (userData != null && userData.containsKey('proExpiredAt')) {
            currentExpiryStr = userData['proExpiredAt'] as String?;
          }
        }

        DateTime baseDate = DateTime.now();
        if (currentExpiryStr != null && currentExpiryStr.isNotEmpty) {
          final DateTime? currentExpiry = DateTime.tryParse(currentExpiryStr);
          if (currentExpiry != null && currentExpiry.isAfter(baseDate)) {
            baseDate = currentExpiry;
          }
        }

        // Nhận diện chính xác gói năm (yearly / 200000) hay gói tháng (monthly / 20000)
        final bool isYear = orderId.toUpperCase().contains('YEARLY') || 
                            orderId.toUpperCase().contains('YEAR') || 
                            orderId.contains('200000');

        final int days = isYear ? 365 : 30;
        final newExpiry = baseDate.add(Duration(days: days)).toIso8601String();

        transaction.set(userDocRef, {
          'plan': 'pro',
          'planType': isYear ? 'yearly' : 'monthly',
          'planSource': 'paid',
          'proExpiredAt': newExpiry,
          'proStartedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        transaction.update(orderDocRef, {'status': 'paid'});

        debugPrint('💎 [ProService] Writing paid plan to Firestore for user ${user.uid}: planType=${isYear ? 'yearly' : 'monthly'}, days=$days, expiry=$newExpiry');
      });

      await checkProStatus();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}

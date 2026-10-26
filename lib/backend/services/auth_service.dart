import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';
import '../models/user_change_model.dart';
import 'api_client.dart';
import 'bank_notification_listener_manager.dart';
import 'pro_service.dart';
import 'sync_service.dart';

import '../../frontend/utils/app_language.dart';
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      return await _firebaseAuth.currentUser?.getIdToken(forceRefresh);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: '252576636037-b0ron8cb2g4u6fo6rqja33om5cop4tl9.apps.googleusercontent.com',
      );
      final googleAccount = await _googleSignIn.authenticate();
      final googleAuth = googleAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential;
      try {
        userCredential = await _firebaseAuth.signInWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          throw Exception(AppLanguage.instance.t('Email này đã được liên kết với phương thức đăng nhập khác.'));
        }
        rethrow;
      }

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception(AppLanguage.instance.t('Đăng nhập Firebase thất bại.'));

      final idToken = await getIdToken(forceRefresh: true);
      UserModel localUser = await _syncWithBackendOrLocal(firebaseUser, idToken, 'google.com');
      return localUser;
    } catch (e) {
      throw Exception(_mapFirebaseErrorToVietnamese(e.toString()));
    }
  }

  Future<UserModel?> signInWithEmail(String emailOrPhone, String password) async {
    try {
      String email = emailOrPhone.trim();
      if (!email.contains('@')) {
        final allUsers = await _dbHelper.getAllUsers();
        final match = allUsers.where((u) => u.email == emailOrPhone || u.email == '$emailOrPhone@mousey.local').toList();
        if (match.isNotEmpty) {
          email = match.first.email;
          if (!email.contains('@')) {
            email = '$email@mousey.local';
          }
        } else {
          email = '$email@mousey.local';
        }
      }

      UserCredential credential;
      try {
        credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (authErr) {
        try {
          credential = await _firebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (_) {
          rethrow;
        }
      }

      final user = credential.user;
      if (user == null) throw Exception(AppLanguage.instance.t('Đăng nhập thất bại.'));

      final idToken = await getIdToken(forceRefresh: true);
      return await _syncWithBackendOrLocal(user, idToken, 'password');
    } catch (e) {
      throw Exception(_mapFirebaseErrorToVietnamese(e.toString()));
    }
  }

  Future<UserModel?> registerWithEmail(String name, String emailOrPhone, String password) async {
    try {
      String email = emailOrPhone.trim();
      if (!email.contains('@')) {
        email = '$email@mousey.local';
      }

      UserCredential credential;
      try {
        credential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          throw Exception(AppLanguage.instance.t('Số điện thoại hoặc email này đã được đăng ký. Vui lòng đăng nhập.'));
        } else {
          rethrow;
        }
      }

      final user = credential.user;
      if (user == null) throw Exception(AppLanguage.instance.t('Đăng ký thất bại.'));

      await user.updateDisplayName(name);

      final idToken = await getIdToken(forceRefresh: true);
      final localUser = await _syncWithBackendOrLocal(user, idToken, 'password');
      
      final newUserModel = localUser.copyWith(name: name, password: password);
      await _dbHelper.insertOrUpdateUser(newUserModel);

      return newUserModel;
    } catch (e) {
      throw Exception(_mapFirebaseErrorToVietnamese(e.toString()));
    }
  }

  Future<void> syncSessionInBackground(User firebaseUser) async {
    try {
      final idToken = await getIdToken(forceRefresh: true);
      final provider = firebaseUser.providerData.isNotEmpty 
          ? firebaseUser.providerData.first.providerId 
          : 'password';
      await _syncWithBackendOrLocal(firebaseUser, idToken, provider);
    } catch (_) {}
  }

  Future<UserModel> _syncWithBackendOrLocal(User firebaseUser, String? idToken, String provider) async {
    final now = DateTime.now().toIso8601String();
    
    final existingLocal = await _dbHelper.getCurrentUser(firebaseUser.uid);

    UserModel userModel = existingLocal ?? UserModel(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? AppLanguage.instance.t('Người dùng'),
      email: firebaseUser.email ?? '',
      password: '',
      photoUrl: firebaseUser.photoURL,
      provider: provider,
      role: firebaseUser.email == 'admin@mousey.com' ? 'admin' : 'user',
      plan: 'free',
      lastLoginAt: now,
      createdAt: now,
    );

    // Đăng ký/cập nhật phiên với backend: server tạo doc users/{uid} với các trường
    // do server quản lý (role, plan, proExpiredAt) mà client không được phép ghi.
    if (idToken != null) {
      try {
        final session = await ApiClient.instance.post('/auth/session');
        if (session['plan'] == 'pro') {
          userModel = userModel.copyWith(plan: 'pro', proExpiredAt: session['proExpiredAt'] as String?);
        }
      } on ApiException catch (e) {
        developer.log('Backend session sync failed (offline fallback): ${e.message}');
      }
    }

    // Fetch from Cloud Firestore to preserve real plan status
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final cloudPlan = data['plan'] as String? ?? 'free';
        final cloudExpiry = data['proExpiredAt'] as String?;
        if (cloudPlan == 'pro') {
          userModel = userModel.copyWith(plan: 'pro', proExpiredAt: cloudExpiry);
          developer.log('💎 [AuthService] Preserved PRO plan from Firestore for user ${firebaseUser.uid}');
        }
      }
    } catch (e) {
      developer.log('Error reading plan from Firestore in AuthService: $e');
    }

    // Preserve existing local PRO plan if active
    if (existingLocal != null && existingLocal.plan == 'pro') {
      userModel = userModel.copyWith(
        plan: existingLocal.plan,
        proExpiredAt: existingLocal.proExpiredAt,
      );
    }

    // Save/update user document in Cloud Firestore so Admin can see all registered users
    try {
      await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).set({
        'name': userModel.name,
        'email': userModel.email,
        // role / plan / proExpiredAt / trialUsed do backend quản lý (firestore.rules chặn client ghi)
        'isActive': userModel.isActive,
        'createdAt': userModel.createdAt,
        'photoUrl': userModel.photoUrl,
        'provider': userModel.provider,
        'lastLoginAt': userModel.lastLoginAt,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log('Error writing user profile to Firestore: $e');
    }

    await _dbHelper.insertOrUpdateUser(userModel);
    return userModel;
  }

  Future<void> signOut() async {
    final uid = _firebaseAuth.currentUser?.uid;
    
    // Ngừng đọc thông báo ngân hàng để không ghi giao dịch vào tài khoản đăng nhập sau
    BankNotificationListenerManager.instance.stopListening();

    // Reset ProService in-memory state so it doesn't leak Pro to the next logged in user
    ProService.instance.resetState();

    if (uid != null) {
      await SyncService.instance.clearSyncData(uid);
      await _dbHelper.clearUserSession(uid);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mousey_is_pro_$uid');
      await prefs.remove('mousey_pro_expired_at_$uid');
      await prefs.remove('mousey_trial_used_$uid');
      await prefs.remove('mousey_remaining_days_$uid');
      await prefs.remove('last_sync_$uid');
      await prefs.remove('mousey_last_sync_$uid');
    }
    
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _firebaseAuth.signOut();
  }

  String? getCurrentUid() {
    return _firebaseAuth.currentUser?.uid;
  }

  String _mapFirebaseErrorToVietnamese(String error) {
    if (error.contains('network-request-failed')) {
      return AppLanguage.instance.t('Không có kết nối Internet. Vui lòng kiểm tra lại mạng.');
    } else if (error.contains('popup-closed-by-user') || error.contains('canceled')) {
      return AppLanguage.instance.t('Bạn đã hủy quá trình đăng nhập.');
    } else if (error.contains('user-disabled')) {
      return AppLanguage.instance.t('Tài khoản này đã bị vô hiệu hóa.');
    } else if (error.contains('invalid-credential') || error.contains('wrong-password') || error.contains('user-not-found') || error.contains('invalid-email')) {
      return AppLanguage.instance.t('Email/SĐT hoặc mật khẩu không chính xác.');
    } else if (error.contains('email-already-in-use')) {
      return AppLanguage.instance.t('Số điện thoại hoặc email này đã được đăng ký. Vui lòng đăng nhập.');
    } else if (error.contains('weak-password')) {
      return AppLanguage.instance.t('Mật khẩu quá yếu (cần ít nhất 6 ký tự).');
    }
    return error.replaceAll('Exception: ', '');
  }

  // Existing methods for local DB auth
  Future<int> registerUser(UserModel user) async {
    return await _dbHelper.registerUser(user);
  }

  Future<UserModel?> loginUser(String emailOrPhone, String password) async {
    return await signInWithEmail(emailOrPhone, password);
  }

  Future<bool> isEmailRegistered(String email) async {
    return await _dbHelper.isEmailRegistered(email);
  }

  Future<int> updatePasswordByEmail(String email, String newPassword) async {
    return await _dbHelper.updatePasswordByEmail(email, newPassword);
  }

  Future<List<UserModel>> getAllUsers() async {
    return await _dbHelper.getAllUsers();
  }

  Future<List<UserModel>> searchUsers(String query) async {
    return await _dbHelper.searchUsers(query);
  }

  Future<int> updateUser(UserModel user) async {
    return await _dbHelper.updateUser(user);
  }

  Future<int> toggleUserActiveStatus(int id, bool currentStatus) async {
    return await _dbHelper.toggleUserActiveStatus(id, currentStatus);
  }

  Future<int> deleteUser(int id) async {
    return await _dbHelper.deleteUser(id);
  }

  Future<Map<String, int>> getUserStats() async {
    return await _dbHelper.getUserStats();
  }

  Future<int> logUserChange({
    required int userId,
    required String userEmail,
    required String changedField,
    required String oldValue,
    required String newValue,
  }) async {
    return await _dbHelper.logUserChange(
      userId: userId,
      userEmail: userEmail,
      changedField: changedField,
      oldValue: oldValue,
      newValue: newValue,
    );
  }

  Future<List<UserChangeModel>> getUserChanges(int userId) async {
    return await _dbHelper.getUserChanges(userId);
  }

  Future<List<UserChangeModel>> getAllUserChanges() async {
    return await _dbHelper.getAllUserChanges();
  }
}

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../database/db_helper.dart';
import '../models/user_model.dart';
import '../models/user_change_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final String _baseUrl = 'http://10.0.2.2:3000'; // Backend REST API URL

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
      // Quan trọng trên Android: Phải truyền serverClientId (Web client ID từ Firebase Console)
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
          throw Exception('Email này đã được liên kết với phương thức đăng nhập khác.');
        }
        rethrow;
      }

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('Đăng nhập Firebase thất bại.');

      final idToken = await getIdToken(forceRefresh: true);
      developer.log(
        '🔥 FIREBASE_ID_TOKEN: $idToken',
        name: 'PiggySmartAuth',
      );
      debugPrint('🔥 FIREBASE_ID_TOKEN: $idToken');
      UserModel localUser = await _syncWithBackendOrLocal(firebaseUser, idToken, 'google.com');
      return localUser;
    } catch (e) {
      throw Exception(_mapFirebaseErrorToVietnamese(e.toString()));
    }
  }

  Future<UserModel> _syncWithBackendOrLocal(User firebaseUser, String? idToken, String provider) async {
    final now = DateTime.now().toIso8601String();
    UserModel userModel = UserModel(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'Người dùng',
      email: firebaseUser.email ?? '',
      password: '',
      photoUrl: firebaseUser.photoURL,
      provider: provider,
      role: firebaseUser.email == 'admin@piggysmart.com' ? 'admin' : 'user',
      plan: 'free',
      lastLoginAt: now,
      createdAt: now,
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/session'),
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email,
          'displayName': firebaseUser.displayName,
          'photoUrl': firebaseUser.photoURL,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        userModel = userModel.copyWith(
          plan: data['plan'] ?? 'free',
          proExpiredAt: data['proExpiredAt'],
          role: data['role'] ?? userModel.role,
        );
      }
    } on SocketException {
      // Offline mode: use cached data
    } catch (_) {}

    await _dbHelper.insertOrUpdateUser(userModel);
    return userModel;
  }

  Future<void> signOut() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid != null) {
      await _dbHelper.clearUserSession(uid);
    }
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  String? getCurrentUid() {
    return _firebaseAuth.currentUser?.uid;
  }

  String _mapFirebaseErrorToVietnamese(String error) {
    if (error.contains('network-request-failed')) {
      return 'Không có kết nối Internet. Vui lòng kiểm tra lại mạng.';
    } else if (error.contains('popup-closed-by-user') || error.contains('canceled')) {
      return 'Bạn đã hủy quá trình đăng nhập.';
    } else if (error.contains('user-disabled')) {
      return 'Tài khoản này đã bị vô hiệu hóa.';
    }
    return error.replaceAll('Exception: ', '');
  }

  // Existing methods for local DB auth
  Future<int> registerUser(UserModel user) async {
    return await _dbHelper.registerUser(user);
  }

  Future<UserModel?> loginUser(String emailOrPhone, String password) async {
    return await _dbHelper.loginUser(emailOrPhone, password);
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

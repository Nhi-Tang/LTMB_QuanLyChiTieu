import '../database/db_helper.dart';
import '../models/user_model.dart';
import '../models/user_change_model.dart';

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

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

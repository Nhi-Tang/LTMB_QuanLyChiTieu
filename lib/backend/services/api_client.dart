import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_config.dart';

/// Lỗi trả về từ backend (hoặc lỗi mạng) với thông điệp đã sẵn sàng hiển thị cho người dùng.
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException(this.message, {this.statusCode});

  /// true khi không kết nối được server (offline, server tắt, timeout)
  bool get isNetworkError => statusCode == null;

  @override
  String toString() => message;
}

/// Client gọi backend FastAPI, tự đính kèm Firebase ID token vào header Authorization.
class ApiClient {
  static final ApiClient instance = ApiClient._init();
  ApiClient._init();

  http.Client _http = http.Client();

  @visibleForTesting
  set httpClient(http.Client client) => _http = client;

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> _send(String method, String path, {Map<String, dynamic>? body}) async {
    var response = await _request(method, path, body: body, forceRefreshToken: false);
    // Token có thể vừa hết hạn: lấy token mới và thử lại 1 lần
    if (response.statusCode == 401) {
      response = await _request(method, path, body: body, forceRefreshToken: true);
    }
    return _decode(response);
  }

  Future<http.Response> _request(String method, String path,
      {Map<String, dynamic>? body, required bool forceRefreshToken}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ApiException('Bạn chưa đăng nhập.', statusCode: 401);
    }
    final token = await user.getIdToken(forceRefreshToken);
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    try {
      final future = method == 'GET'
          ? _http.get(uri, headers: headers)
          : _http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
      return await future.timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw ApiException('Máy chủ phản hồi quá lâu, vui lòng thử lại.');
    } on SocketException {
      throw ApiException('Không kết nối được máy chủ. Kiểm tra mạng và thử lại.');
    } on http.ClientException {
      throw ApiException('Không kết nối được máy chủ. Kiểm tra mạng và thử lại.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      data = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    }

    final detail = data is Map ? data['detail'] : null;
    throw ApiException(
      detail is String && detail.isNotEmpty ? detail : 'Lỗi máy chủ (${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }
}

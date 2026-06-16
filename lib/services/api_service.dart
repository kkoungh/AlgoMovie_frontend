import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal()
      : _client = http.Client(),
        _storage = const FlutterSecureStorage();

  static const _timeout = Duration(seconds: 30);

  http.Client _client;
  FlutterSecureStorage _storage;

  void configureForTesting({
    http.Client? client,
    FlutterSecureStorage? storage,
  }) {
    if (client != null) _client = client;
    if (storage != null) _storage = storage;
  }

  Future<String?> getToken() => _storage.read(key: 'access_token');
  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // access token 만료 시 refresh token으로 자동 갱신
  Future<void> _refreshAccessToken() async {
    final rt = await _storage.read(key: 'refresh_token');
    if (rt == null) return;
    try {
      final res = await _client
          .post(
            Uri.parse('${ApiConstants.baseUrl}/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': rt}),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        await _storage.write(key: 'access_token', value: data['accessToken'] as String);
      }
    } catch (_) {}
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    var res = await _client
        .get(
          Uri.parse('${ApiConstants.baseUrl}$path'),
          headers: await _headers(auth: auth),
        )
        .timeout(_timeout);
    if (auth && res.statusCode == 401) {
      await _refreshAccessToken();
      res = await _client
          .get(
            Uri.parse('${ApiConstants.baseUrl}$path'),
            headers: await _headers(auth: auth),
          )
          .timeout(_timeout);
    }
    return _parse(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    var res = await _client
        .post(
          Uri.parse('${ApiConstants.baseUrl}$path'),
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    if (auth && res.statusCode == 401) {
      await _refreshAccessToken();
      res = await _client
          .post(
            Uri.parse('${ApiConstants.baseUrl}$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    }
    return _parse(res);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    var res = await _client
        .patch(
          Uri.parse('${ApiConstants.baseUrl}$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    if (res.statusCode == 401) {
      await _refreshAccessToken();
      res = await _client
          .patch(
            Uri.parse('${ApiConstants.baseUrl}$path'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    }
    return _parse(res);
  }

  Future<dynamic> delete(String path) async {
    var res = await _client
        .delete(
          Uri.parse('${ApiConstants.baseUrl}$path'),
          headers: await _headers(),
        )
        .timeout(_timeout);
    if (res.statusCode == 401) {
      await _refreshAccessToken();
      res = await _client
          .delete(
            Uri.parse('${ApiConstants.baseUrl}$path'),
            headers: await _headers(),
          )
          .timeout(_timeout);
    }
    if (res.statusCode == 204) return null;
    return _parse(res);
  }

  dynamic _parse(http.Response res) {
    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body.isEmpty) return null;
      return jsonDecode(body);
    }
    Map<String, dynamic> err = {};
    try {
      err = jsonDecode(body);
    } catch (_) {}
    final msg = err['message'] ?? '요청에 실패했습니다. (${res.statusCode})';
    throw ApiException(msg, res.statusCode, err['code']);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? code;
  ApiException(this.message, this.statusCode, this.code);
  @override
  String toString() => message;
}

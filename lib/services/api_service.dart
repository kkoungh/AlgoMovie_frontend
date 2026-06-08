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

  http.Client _client;
  FlutterSecureStorage _storage;

  /// Replaces network and storage dependencies in tests without changing
  /// production construction.
  void configureForTesting({
    http.Client? client,
    FlutterSecureStorage? storage,
  }) {
    if (client != null) _client = client;
    if (storage != null) _storage = storage;
  }

  /// Reads the current access token from secure storage.
  Future<String?> getToken() => _storage.read(key: 'access_token');

  /// Persists access and refresh tokens after successful login.
  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  /// Removes local authentication tokens.
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

  /// Sends a GET request to a backend API path.
  Future<dynamic> get(String path, {bool auth = true}) async {
    final res = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: await _headers(auth: auth),
    );
    return _parse(res);
  }

  /// Sends a JSON POST request to a backend API path.
  Future<dynamic> post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final res = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  /// Sends a JSON PATCH request to a backend API path.
  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await _client.patch(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  /// Sends a DELETE request to a backend API path.
  Future<dynamic> delete(String path) async {
    final res = await _client.delete(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: await _headers(),
    );
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

/// Error raised for non-2xx API responses.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? code;

  ApiException(this.message, this.statusCode, this.code);

  @override
  String toString() => message;
}

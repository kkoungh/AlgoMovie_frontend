import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() => _storage.read(key: 'access_token');
  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token',  value: access);
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

  Future<dynamic> get(String path, {bool auth = true}) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: await _headers(auth: auth),
    );
    return _parse(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(
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
    try { err = jsonDecode(body); } catch (_) {}
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

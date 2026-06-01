import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;

  AuthStatus get status => _status;
  User?       get user   => _user;
  String?     get error  => _error;

  Future<void> checkAuth() async {
    final token = await _api.getToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final data = await _api.get('/users/me');
      _user   = User.fromJson(data);
      _status = AuthStatus.authenticated;
    } catch (_) {
      await _api.clearTokens();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    try {
      final data = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      }, auth: false);
      await _api.saveTokens(data['accessToken'], data['refreshToken']);
      _user   = User.fromJson(data['user'] is Map ? data['user'] : {
        'userId': data['user']['userId'],
        'email': email,
        'nickname': data['user']['nickname'],
        'ratingCount': 0,
        'preferredGenres': [],
      });
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String nickname,
    required List<int> genres,
  }) async {
    _error = null;
    try {
      await _api.post('/auth/register', {
        'email':    email,
        'password': password,
        'nickname': nickname,
        'genres':   genres,
      }, auth: false);
      return await login(email, password);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearTokens();
    _user   = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final data = await _api.get('/users/me');
      _user = User.fromJson(data);
      notifyListeners();
    } catch (_) {}
  }
}

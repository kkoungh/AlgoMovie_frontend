import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    return 'http://10.0.2.2:3000/api';
  }
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';
}

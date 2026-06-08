class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'ALGOMOVIE_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';
}

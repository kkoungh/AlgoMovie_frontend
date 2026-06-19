import 'dart:convert';

import 'package:algomovie/providers/auth_provider.dart';
import 'package:algomovie/providers/movie_provider.dart';
import 'package:algomovie/providers/recommendation_provider.dart';
import 'package:algomovie/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _MemStorage extends FlutterSecureStorage {
  final Map<String, String> _map = {};

  @override
  Future<String?> read({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async => _map[key];

  @override
  Future<void> write({required String key, required String? value, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    if (value == null) { _map.remove(key); } else { _map[key] = value; }
  }

  @override
  Future<void> delete({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async => _map.remove(key);
}

http.Response _json(Object body, {int status = 200}) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  late _MemStorage storage;

  void setupApi(http.Response Function(http.Request) handler) {
    storage = _MemStorage();
    storage._map['access_token'] = 'test-token';
    ApiService().configureForTesting(
      storage: storage,
      client: MockClient((req) async => handler(req)),
    );
  }

  group('RecommendationProvider state machine', () {
    test('FR-64: markVoted adds movieId to votedMovieIds and notifies', () {
      final provider = RecommendationProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.markVoted(42);

      expect(provider.votedMovieIds, contains(42));
      expect(notified, isTrue);
    });

    test('FR-64: removeRecommendation adds to disliked set', () {
      final provider = RecommendationProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.removeRecommendation(99);

      expect(notified, isTrue);
    });

    test('clear resets recommendations, weights, votedMovieIds, and cache flag', () {
      final provider = RecommendationProvider();
      provider.markVoted(1);
      provider.markVoted(2);

      provider.clear();

      expect(provider.recommendations, isEmpty);
      expect(provider.weights, isNull);
      expect(provider.fromCache, isFalse);
      expect(provider.votedMovieIds, isEmpty);
    });

    test('loadRecommendations populates recommendations from API', () async {
      setupApi((req) => _json({
            'recommendations': [
              {'movieId': 10, 'title': '추천 영화', 'genres': ['Action'], 'avgRating': 4.5, 'ratingCount': 50},
            ],
            'sparePool': [],
            'weights': {'alpha': 0.5, 'beta': 0.5, 'gamma': 0.0, 'segment': 'MID_USER'},
            'fromCache': false,
            'isNewUser': false,
          }));

      final provider = RecommendationProvider();
      await provider.loadRecommendations();

      expect(provider.recommendations, hasLength(1));
      expect(provider.recommendations.first.title, '추천 영화');
      expect(provider.loading, isFalse);
      expect(provider.error, isNull);
    });

    test('loadRecommendations sets error on API failure', () async {
      setupApi((_) => _json({'message': '서버 오류', 'code': 'SERVER_ERROR'}, status: 500));

      final provider = RecommendationProvider();
      await provider.loadRecommendations();

      expect(provider.recommendations, isEmpty);
      expect(provider.error, isNotNull);
      expect(provider.loading, isFalse);
    });

    test('loadRecommendations marks fromCache true when API returns cached result', () async {
      setupApi((_) => _json({
            'recommendations': [
              {'movieId': 5, 'title': '캐시 영화', 'genres': [], 'avgRating': 3.0, 'ratingCount': 10},
            ],
            'sparePool': [],
            'weights': null,
            'fromCache': true,
            'isNewUser': false,
          }));

      final provider = RecommendationProvider();
      await provider.loadRecommendations();

      expect(provider.fromCache, isTrue);
    });
  });

  group('AuthProvider state machine', () {
    test('login sets authenticated status and user on success', () async {
      setupApi((_) => _json({
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
            'user': {
              'userId': 7,
              'email': 'user@test.com',
              'nickname': '홍길동',
              'ratingCount': 0,
              'preferredGenres': [],
            },
          }));

      final provider = AuthProvider();
      final result = await provider.login('user@test.com', 'password123');

      expect(result, isTrue);
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.user?.email, 'user@test.com');
      expect(provider.error, isNull);
    });

    test('login sets error and returns false on API failure', () async {
      setupApi((_) => _json({'message': '인증 실패', 'code': 'INVALID_CREDENTIALS'}, status: 401));

      final provider = AuthProvider();
      final result = await provider.login('wrong@test.com', 'wrongpw');

      expect(result, isFalse);
      expect(provider.status, isNot(AuthStatus.authenticated));
      expect(provider.error, isNotNull);
    });

    test('logout sets unauthenticated status and clears user', () async {
      setupApi((_) => _json({'message': '인증 실패'}, status: 401));

      final provider = AuthProvider();
      await provider.logout();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.user, isNull);
    });

    test('checkAuth returns unauthenticated when no token is stored', () async {
      storage = _MemStorage(); // no token in storage
      ApiService().configureForTesting(storage: storage, client: MockClient((_) async => throw Exception('should not call')));

      final provider = AuthProvider();
      await provider.checkAuth();

      expect(provider.status, AuthStatus.unauthenticated);
    });

    test('checkAuth restores authenticated state from valid token', () async {
      setupApi((_) => _json({
            'userId': 3,
            'email': 'restored@test.com',
            'nickname': '복원유저',
            'ratingCount': 5,
            'preferredGenres': [],
          }));

      final provider = AuthProvider();
      await provider.checkAuth();

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.user?.userId, 3);
    });

    test('checkAuth clears tokens and sets unauthenticated on API error', () async {
      setupApi((_) => _json({'message': '인증 실패', 'code': 'UNAUTHORIZED'}, status: 401));

      final provider = AuthProvider();
      await provider.checkAuth();

      expect(provider.status, AuthStatus.unauthenticated);
    });

    test('refreshProfile updates user data from API', () async {
      setupApi((_) => _json({
            'userId': 7,
            'email': 'user@test.com',
            'nickname': '업데이트유저',
            'ratingCount': 10,
            'preferredGenres': [
              {'genreId': 1, 'name': 'Action'},
            ],
          }));

      final provider = AuthProvider();
      await provider.refreshProfile();

      expect(provider.user?.nickname, '업데이트유저');
      expect(provider.user?.ratingCount, 10);
    });
  });

  group('MovieProvider state machine', () {
    test('loadMovies populates movies list from API', () async {
      setupApi((_) => _json({
            'movies': [
              {'movieId': 1, 'title': '영화A', 'genres': ['Action'], 'avgRating': 4.0, 'ratingCount': 30},
              {'movieId': 2, 'title': '영화B', 'genres': ['Drama'], 'avgRating': 3.5, 'ratingCount': 20},
            ],
          }));

      final provider = MovieProvider();
      await provider.loadMovies();

      expect(provider.movies, hasLength(2));
      expect(provider.loading, isFalse);
      expect(provider.error, isNull);
    });

    test('loadMovies with genre passes genre query param', () async {
      String? capturedPath;
      setupApi((req) {
        capturedPath = req.url.toString();
        return _json({'movies': []});
      });

      final provider = MovieProvider();
      await provider.loadMovies(genre: 'Action');

      expect(capturedPath, contains('genre=Action'));
    });

    test('loadGenres prepends 전체 to the genre list', () async {
      setupApi((_) => _json({
            'genres': [
              {'genreId': 1, 'name': 'Action'},
              {'genreId': 2, 'name': 'Drama'},
            ],
          }));

      final provider = MovieProvider();
      await provider.loadGenres();

      expect(provider.genres.first, '전체');
      expect(provider.genres, hasLength(3));
    });

    test('searchMovies with empty query clears results without API call', () async {
      var apiCalled = false;
      setupApi((_) {
        apiCalled = true;
        return _json({'movies': []});
      });

      final provider = MovieProvider();
      await provider.searchMovies('   ');

      expect(apiCalled, isFalse);
      expect(provider.searchResults, isEmpty);
    });

    test('searchMovies returns results from API', () async {
      setupApi((_) => _json({
            'movies': [
              {'movieId': 5, 'title': '검색결과', 'genres': [], 'avgRating': 4.2, 'ratingCount': 15},
            ],
          }));

      final provider = MovieProvider();
      await provider.searchMovies('검색');

      expect(provider.searchResults, hasLength(1));
      expect(provider.searchLoading, isFalse);
    });

    test('rateMovie returns true and increments ratingRevision on success', () async {
      setupApi((_) => _json({'ratingId': 1}));

      final provider = MovieProvider();
      final before = provider.ratingRevision;
      final result = await provider.rateMovie(1, 4.5, review: '좋아요');

      expect(result, isTrue);
      expect(provider.ratingRevision, before + 1);
    });

    test('submitFeedback returns true on success', () async {
      setupApi((_) => _json({}));

      final provider = MovieProvider();
      final result = await provider.submitFeedback(1, 'LIKE');

      expect(result, isTrue);
    });

    test('toggleWishlist returns true and increments wishlistRevision on success', () async {
      setupApi((_) => _json({'added': true}));

      final provider = MovieProvider();
      final before = provider.wishlistRevision;
      final result = await provider.toggleWishlist(1);

      expect(result, isTrue);
      expect(provider.wishlistRevision, before + 1);
    });

    test('loadMovies sets error on API failure', () async {
      setupApi((_) => _json({'message': '서버 오류'}, status: 500));

      final provider = MovieProvider();
      await provider.loadMovies();

      expect(provider.error, isNotNull);
      expect(provider.loading, isFalse);
    });

    test('loadPopularMovies sets popularMovies list', () async {
      setupApi((_) => _json({
            'movies': [
              {'movieId': 11, 'title': '인기영화', 'genres': ['Action'], 'avgRating': 4.8, 'ratingCount': 500},
            ],
          }));

      final provider = MovieProvider();
      await provider.loadPopularMovies(period: 'monthly');

      expect(provider.popularMovies, hasLength(1));
      expect(provider.popularPeriod, 'monthly');
      expect(provider.popularLoading, isFalse);
    });

    test('loadMovieDetail returns movie and increments historyRevision', () async {
      setupApi((_) => _json({
            'movieId': 7, 'title': '상세영화', 'genres': ['Drama'],
            'avgRating': 4.1, 'ratingCount': 80,
          }));

      final provider = MovieProvider();
      final before = provider.historyRevision;
      final movie = await provider.loadMovieDetail(7);

      expect(movie?.title, '상세영화');
      expect(provider.currentMovie?.movieId, 7);
      expect(provider.historyRevision, before + 1);
    });

    test('loadMovieDetail returns null on error', () async {
      setupApi((_) => _json({'message': '찾을 수 없음'}, status: 404));

      final provider = MovieProvider();
      final movie = await provider.loadMovieDetail(999);

      expect(movie, isNull);
    });

    test('loadSimilarMovies returns similar movie list', () async {
      setupApi((_) => _json({
            'movies': [
              {'movieId': 3, 'title': '유사영화', 'genres': ['Action'], 'avgRating': 3.8, 'ratingCount': 40},
            ],
          }));

      final provider = MovieProvider();
      final result = await provider.loadSimilarMovies(1);

      expect(result, hasLength(1));
      expect(result.first.movieId, 3);
    });

    test('fetchWishlistIds returns a set of movie IDs', () async {
      setupApi((_) => _json({
            'wishlist': [
              {'movie': {'movieId': 10, 'title': '찜영화', 'genres': [], 'avgRating': 0, 'ratingCount': 0}},
              {'movie': {'movieId': 20, 'title': '찜영화2', 'genres': [], 'avgRating': 0, 'ratingCount': 0}},
            ],
          }));

      final provider = MovieProvider();
      final ids = await provider.fetchWishlistIds();

      expect(ids, containsAll([10, 20]));
    });

    test('fetchMyRatings returns list of RatingItems', () async {
      setupApi((_) => _json({
            'reviews': [
              {
                'ratingId': 1, 'score': 4.0, 'review': '좋아요',
                'createdAt': '2026-06-01T00:00:00Z',
                'movie': {'movieId': 5, 'title': '평가영화', 'genres': [], 'avgRating': 4.0, 'ratingCount': 10},
              },
            ],
          }));

      final provider = MovieProvider();
      final ratings = await provider.fetchMyRatings();

      expect(ratings, hasLength(1));
      expect(ratings.first.score, 4.0);
    });

    test('clearSearch resets searchResults and notifies listeners', () {
      final provider = MovieProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      provider.clearSearch();

      expect(provider.searchResults, isEmpty);
      expect(notified, isTrue);
    });

    test('selectGenre filters movies by genre', () async {
      setupApi((_) => _json({
            'movies': [
              {'movieId': 1, 'title': '액션영화', 'genres': ['Action'], 'avgRating': 4.0, 'ratingCount': 10},
            ],
          }));

      final provider = MovieProvider();
      await provider.selectGenre('Action');

      expect(provider.selectedGenre, 'Action');
    });
  });
}

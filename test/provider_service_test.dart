import 'dart:convert';

import 'package:algomovie/models/movie.dart';
import 'package:algomovie/models/rating.dart';
import 'package:algomovie/models/user.dart';
import 'package:algomovie/providers/auth_provider.dart';
import 'package:algomovie/providers/movie_provider.dart';
import 'package:algomovie/providers/recommendation_provider.dart';
import 'package:algomovie/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

http.Response jsonResponse(Object body, {int statusCode = 200}) =>
    http.Response(
      jsonEncode(body),
      statusCode,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> movieJson({int id = 1, String title = 'Movie'}) => {
      'movieId': id,
      'title': title,
      'genres': ['Drama'],
      'director': 'Director',
      'posterPath': '/poster.png',
      'releaseYear': 2026,
      'avgRating': 4.5,
      'ratingCount': 12,
      'finalScore': 0.9,
    };

void main() {
  late MemorySecureStorage storage;
  late List<http.Request> requests;

  void configure(http.Response Function(http.Request request) handler) {
    storage = MemorySecureStorage();
    storage.values['access_token'] = 'access-token';
    requests = [];
    ApiService().configureForTesting(
      storage: storage,
      client: MockClient((request) async {
        requests.add(request);
        return handler(request);
      }),
    );
  }

  test('models map optional fields and poster URLs safely', () {
    final movie = Movie.fromJson({
      'movieId': 10,
      'title': 'Mapped',
      'genres': null,
      'avgRating': null,
      'ratingCount': null,
      'posterPath': '/poster.png',
    });
    final user = User.fromJson({
      'userId': 7,
      'email': 'tester@example.com',
      'nickname': 'tester',
      'preferredGenres': [
        {'genreId': 1, 'name': 'Action'},
      ],
    });
    final rating = RatingItem.fromJson({
      'ratingId': 3,
      'score': 4,
      'review': null,
      'createdAt': '2026-06-08T00:00:00Z',
      'movie': movieJson(id: 10),
    });

    expect(movie.genres, isEmpty);
    expect(movie.avgRating, 0);
    expect(movie.ratingCount, 0);
    expect(movie.posterUrl, 'https://image.tmdb.org/t/p/w500/poster.png');
    expect(user.preferredGenres.single.name, 'Action');
    expect(rating.movie.movieId, 10);
  });

  test(
      'ApiService stores tokens, sends bearer headers, and parses empty deletes',
      () async {
    configure((request) {
      expect(request.headers['authorization'], 'Bearer access-token');
      return http.Response('', 204);
    });

    await ApiService().saveTokens('access-token', 'refresh-token');
    expect(await ApiService().getToken(), 'access-token');
    expect(await ApiService().delete('/auth/withdraw'), isNull);
    await ApiService().clearTokens();
    expect(await ApiService().getToken(), isNull);
  });

  test('ApiService throws structured exceptions for error responses', () async {
    configure((_) => jsonResponse({
          'message': 'bad request',
          'code': 'BAD_REQUEST',
        }, statusCode: 400));

    await expectLater(
      ApiService().get('/broken', auth: false),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 400)
          .having((e) => e.code, 'code', 'BAD_REQUEST')),
    );
  });

  test(
      'MovieProvider loads backend-shaped lists, search results, detail, and similar movies',
      () async {
    configure((request) {
      final path = request.url.path;
      final query = request.url.query;
      if (path.endsWith('/genres')) {
        return jsonResponse({
          'genres': [
            {'genreId': 1, 'name': 'Drama'},
          ],
        });
      }
      if (path.endsWith('/movies') && query.contains('genre=Drama')) {
        return jsonResponse({
          'movies': [movieJson(id: 2, title: 'Drama Movie')]
        });
      }
      if (path.endsWith('/movies/search')) {
        return jsonResponse({
          'movies': [movieJson(id: 3, title: 'Search Movie')]
        });
      }
      if (path.endsWith('/movies/2/similar')) {
        return jsonResponse({
          'movies': [movieJson(id: 4, title: 'Similar Movie')]
        });
      }
      if (path.endsWith('/movies/2')) {
        return jsonResponse(movieJson(id: 2, title: 'Detail Movie'));
      }
      return jsonResponse({
        'movies': [movieJson()]
      });
    });
    final provider = MovieProvider();

    await provider.loadGenres();
    await provider.selectGenre('Drama');
    await provider.searchMovies('search');
    final detail = await provider.loadMovieDetail(2);
    final similar = await provider.loadSimilarMovies(2);

    expect(provider.genres, ['전체', 'Drama']);
    expect(provider.movies.single.title, 'Drama Movie');
    expect(provider.searchResults.single.title, 'Search Movie');
    expect(detail?.title, 'Detail Movie');
    expect(similar.single.title, 'Similar Movie');
  });

  test(
      'MovieProvider handles empty searches, API failures, and authenticated writes',
      () async {
    configure((request) {
      if (request.url.path.endsWith('/feedback')) {
        return jsonResponse({'ok': true});
      }
      if (request.url.path.endsWith('/wishlist/9')) {
        return jsonResponse({'added': true});
      }
      if (request.url.path.endsWith('/ratings')) {
        return jsonResponse({'ratingId': 1}, statusCode: 201);
      }
      return jsonResponse({'message': 'failure'}, statusCode: 500);
    });
    final provider = MovieProvider();

    await provider.searchMovies('   ');
    await provider.loadMovies();
    final detail = await provider.loadMovieDetail(404);
    final similar = await provider.loadSimilarMovies(404);
    final rated = await provider.rateMovie(9, 5, review: 'great');
    final feedback = await provider.submitFeedback(9, 'LIKE');
    final wishlist = await provider.toggleWishlist(9);

    expect(provider.searchResults, isEmpty);
    expect(provider.error, contains('failure'));
    expect(detail, isNull);
    expect(similar, isEmpty);
    expect(rated, isTrue);
    expect(feedback, isTrue);
    expect(wishlist, isTrue);
    expect(requests.last.url.path, endsWith('/wishlist/9'));
  });

  test('AuthProvider checks, logs in, registers, refreshes, and logs out',
      () async {
    configure((request) {
      if (request.url.path.endsWith('/users/me')) {
        return jsonResponse({
          'userId': 7,
          'email': 'tester@example.com',
          'nickname': 'tester',
          'ratingCount': 1,
          'preferredGenres': [],
        });
      }
      if (request.url.path.endsWith('/auth/login')) {
        return jsonResponse({
          'accessToken': 'new-access',
          'refreshToken': 'new-refresh',
          'user': {
            'userId': 7,
            'email': 'tester@example.com',
            'nickname': 'tester',
          },
        });
      }
      if (request.url.path.endsWith('/auth/register')) {
        return jsonResponse({'userId': 7}, statusCode: 201);
      }
      return jsonResponse({});
    });
    final provider = AuthProvider();

    await provider.checkAuth();
    final loggedIn = await provider.login('tester@example.com', 'password123');
    final registered = await provider.register(
      email: 'new@example.com',
      password: 'password123',
      nickname: 'newbie',
      genres: [1, 2, 3],
    );
    await provider.refreshProfile();
    await provider.logout();

    expect(provider.user?.nickname, isNull);
    expect(loggedIn, isTrue);
    expect(registered, isTrue);
    expect(provider.status, AuthStatus.unauthenticated);
  });

  test('AuthProvider clears invalid stored tokens and exposes API errors',
      () async {
    configure((request) {
      if (request.url.path.endsWith('/users/me')) {
        return jsonResponse({'message': 'unauthorized'}, statusCode: 401);
      }
      return jsonResponse({'message': 'invalid credentials'}, statusCode: 401);
    });
    final provider = AuthProvider();

    await provider.checkAuth();
    final loggedIn = await provider.login('bad@example.com', 'wrong');

    expect(loggedIn, isFalse);
    expect(provider.status, AuthStatus.unauthenticated);
    expect(provider.error, 'invalid credentials');
    expect(await ApiService().getToken(), isNull);
  });

  test(
      'RecommendationProvider loads, defaults, handles errors, and clears state',
      () async {
    configure((request) {
      if (request.url.query.contains('error=true')) {
        return jsonResponse({'message': 'recommendation failed'},
            statusCode: 500);
      }
      return jsonResponse({
        'recommendations': [movieJson(id: 30, title: 'Recommended')],
        'weights': {'segment': 'new'},
        'fromCache': true,
      });
    });
    final provider = RecommendationProvider();

    await provider.loadRecommendations();
    expect(provider.recommendations.single.title, 'Recommended');
    expect(provider.weights?['segment'], 'new');
    expect(provider.fromCache, isTrue);

    provider.clear();
    expect(provider.recommendations, isEmpty);

    ApiService().configureForTesting(
      storage: storage,
      client: MockClient(
          (_) async => jsonResponse({'message': 'failed'}, statusCode: 500)),
    );
    await provider.loadRecommendations();
    expect(provider.error, contains('failed'));
    expect(provider.loading, isFalse);
  });
}

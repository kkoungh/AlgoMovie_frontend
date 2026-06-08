import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../services/api_service.dart';

class MovieProvider extends ChangeNotifier {
  final _api = ApiService();

  List<Movie> _movies = [];
  List<Movie> _searchResults = [];
  List<String> _genres = [];
  String _selectedGenre = '전체';
  bool _loading = false;
  bool _searchLoading = false;
  String? _error;
  Movie? _currentMovie;

  List<Movie> get movies => _movies;
  List<Movie> get searchResults => _searchResults;
  List<String> get genres => _genres;
  String get selectedGenre => _selectedGenre;
  bool get loading => _loading;
  bool get searchLoading => _searchLoading;
  String? get error => _error;
  Movie? get currentMovie => _currentMovie;

  /// Loads genre names from the backend and prepends the local "all" option.
  Future<void> loadGenres() async {
    try {
      final data = await _api.get('/genres', auth: false);
      final list = _extractList(data, 'genres');
      _genres = ['전체', ...list.map((g) => g['name'].toString())];
      notifyListeners();
    } catch (_) {}
  }

  /// Loads movies with optional genre filtering using the backend pagination
  /// response shape: `{ movies, total, page, limit }`.
  Future<void> loadMovies({String? genre}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final path = genre != null && genre != '전체'
          ? '/movies?genre=${Uri.encodeComponent(genre)}'
          : '/movies';
      final data = await _api.get(path, auth: false);
      _movies = _extractList(data, 'movies')
          .map((m) => Movie.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Updates the selected genre and refreshes the movie list for that genre.
  Future<void> selectGenre(String genre) async {
    _selectedGenre = genre;
    await loadMovies(genre: genre);
  }

  /// Searches movies by title/director/cast and clears results for blank input.
  Future<void> searchMovies(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _searchLoading = true;
    notifyListeners();
    try {
      final data = await _api
          .get('/movies/search?q=${Uri.encodeComponent(query)}', auth: false);
      _searchResults = _extractList(data, 'movies')
          .map((m) => Movie.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _searchResults = [];
    } finally {
      _searchLoading = false;
      notifyListeners();
    }
  }

  /// Loads one movie detail and stores it as the current movie.
  Future<Movie?> loadMovieDetail(int movieId) async {
    try {
      final data = await _api.get('/movies/$movieId', auth: false);
      _currentMovie = Movie.fromJson(data as Map<String, dynamic>);
      notifyListeners();
      return _currentMovie;
    } catch (_) {
      return null;
    }
  }

  /// Loads movies similar to the selected movie.
  Future<List<Movie>> loadSimilarMovies(int movieId) async {
    try {
      final data = await _api.get('/movies/$movieId/similar', auth: false);
      return _extractList(data, 'movies')
          .map((m) => Movie.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Writes a user rating and optional review for a movie.
  Future<bool> rateMovie(int movieId, double score, {String? review}) async {
    try {
      await _api.post('/ratings', {
        'movieId': movieId,
        'score': score,
        if (review != null && review.isNotEmpty) 'review': review,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sends recommendation feedback such as LIKE, DISLIKE, or REMOVE.
  Future<bool> submitFeedback(int movieId, String type) async {
    try {
      await _api.post('/feedback', {
        'movieId': movieId,
        'feedbackType': type,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Toggles the movie in the authenticated user's wishlist.
  Future<bool> toggleWishlist(int movieId) async {
    try {
      await _api.post('/wishlist/$movieId', {});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clears the in-memory search results shown on the search screen.
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  List<dynamic> _extractList(dynamic data, String key) {
    if (data is Map<String, dynamic>) {
      return data[key] as List<dynamic>? ?? [];
    }
    return data as List<dynamic>;
  }
}

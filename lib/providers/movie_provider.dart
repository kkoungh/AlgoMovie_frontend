import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/movie.dart';

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

  List<Movie>  get movies        => _movies;
  List<Movie>  get searchResults => _searchResults;
  List<String> get genres        => _genres;
  String       get selectedGenre => _selectedGenre;
  bool         get loading       => _loading;
  bool         get searchLoading => _searchLoading;
  String?      get error         => _error;
  Movie?       get currentMovie  => _currentMovie;

  Future<void> loadGenres() async {
    try {
      final data = await _api.get('/genres') as Map<String, dynamic>;
      final list = data['genres'] as List<dynamic>;
      _genres = ['전체', ...list.map((g) => g['name'].toString())];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadMovies({String? genre}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final path = genre != null && genre != '전체'
          ? '/movies?genre=${Uri.encodeComponent(genre)}'
          : '/movies';
      final data = await _api.get(path) as Map<String, dynamic>;
      final list = data['movies'] as List<dynamic>;
      _movies = list.map((m) => Movie.fromJson(m as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> selectGenre(String genre) async {
    _selectedGenre = genre;
    await loadMovies(genre: genre);
  }

  Future<void> searchMovies(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _searchLoading = true;
    notifyListeners();
    try {
      final data = await _api.get('/movies/search?q=${Uri.encodeComponent(query)}') as Map<String, dynamic>;
      final list = data['movies'] as List<dynamic>;
      _searchResults = list.map((m) => Movie.fromJson(m as Map<String, dynamic>)).toList();
    } catch (_) {
      _searchResults = [];
    } finally {
      _searchLoading = false;
      notifyListeners();
    }
  }

  Future<Movie?> loadMovieDetail(int movieId) async {
    try {
      final data = await _api.get('/movies/$movieId');
      _currentMovie = Movie.fromJson(data as Map<String, dynamic>);
      notifyListeners();
      return _currentMovie;
    } catch (_) {
      return null;
    }
  }

  Future<List<Movie>> loadSimilarMovies(int movieId) async {
    try {
      final data = await _api.get('/movies/$movieId/similar') as Map<String, dynamic>;
      final list = data['movies'] as List<dynamic>;
      return list.map((m) => Movie.fromJson(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> rateMovie(int movieId, double score, {String? review}) async {
    try {
      await _api.post('/ratings', {
        'movieId': movieId,
        'score':   score,
        if (review != null && review.isNotEmpty) 'review': review,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitFeedback(int movieId, String type) async {
    try {
      await _api.post('/feedback', {
        'movieId': movieId,
        'type':    type,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleWishlist(int movieId) async {
    try {
      await _api.post('/wishlist/$movieId', {});
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
}

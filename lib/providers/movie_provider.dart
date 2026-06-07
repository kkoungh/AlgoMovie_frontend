import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/movie.dart';

class MovieProvider extends ChangeNotifier {
  final _api = ApiService();

  List<Movie> _movies = [];
  List<Movie> _searchResults = [];
  List<Movie> _popularMovies = [];
  List<String> _genres = [];
  String _selectedGenre = '전체';
  bool _loading = false;
  bool _searchLoading = false;
  bool _popularLoading = false;
  String? _error;
  Movie? _currentMovie;

  // 🌟 [추가] 화면 새로고침 감지용 내부 변수 선언
  int _ratingRevision = 0;
  int _wishlistRevision = 0;

  String _popularPeriod = 'weekly';

  List<Movie>  get movies         => _movies;
  List<Movie>  get searchResults  => _searchResults;
  List<Movie>  get popularMovies  => _popularMovies;
  List<String> get genres         => _genres;
  String       get selectedGenre  => _selectedGenre;
  bool         get loading        => _loading;
  bool         get searchLoading  => _searchLoading;
  bool         get popularLoading => _popularLoading;
  String?      get error          => _error;
  Movie?       get currentMovie   => _currentMovie;

  // 🌟 [추가] 외부 화면(Mypage, Wishlist)에서 접근할 Getter 선언
  int get ratingRevision => _ratingRevision;
  int get wishlistRevision => _wishlistRevision;

  String get popularPeriod => _popularPeriod;

  Future<void> loadGenres() async {
    try {
      final data = await _api.get('/genres') as Map<String, dynamic>;
      final list = data['genres'] as List<dynamic>;
      _genres = ['전체', ...list.map((g) => g['name'].toString())];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadMovies({String? genre, String? country}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final params = <String>[];
      if (genre != null && genre != '전체') params.add('genre=${Uri.encodeComponent(genre)}');
      if (country != null) params.add('country=${Uri.encodeComponent(country)}');
      final path = params.isEmpty ? '/movies' : '/movies?${params.join('&')}';
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

  Future<void> loadPopularMovies({String period = 'weekly'}) async {
    _popularPeriod = period; // 🌟 [추가] 현재 선택된 기간(weekly, monthly 등)을 저장합니다.
    _popularLoading = true;
    notifyListeners();
    try {
      final data = await _api.get('/movies/popular?period=$period') as Map<String, dynamic>;
      final list = data['movies'] as List<dynamic>;
      _popularMovies = list.map((m) => Movie.fromJson(m as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _popularLoading = false;
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
      
      // 🌟 [추가] 평점 등록 성공 시 리비전 값을 올려 마이페이지가 알게 함
      _ratingRevision++;
      notifyListeners();
      
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
      
      // 🌟 [추가] 찜하기 토글 성공 시 리비전 값을 올려 위시리스트가 알게 함
      _wishlistRevision++;
      notifyListeners();
      
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Set<int>> fetchWishlistIds() async {
    try {
      final data = await _api.get('/mypage/wishlist') as Map<String, dynamic>;
      final list = data['wishlist'] as List<dynamic>;
      return list
          .map((e) => int.parse((e as Map<String, dynamic>)['movie']['movieId'].toString()))
          .toSet();
    } catch (_) {
      return {};
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
}
import 'package:algomovie/models/movie.dart';
import 'package:algomovie/models/rating.dart';
import 'package:algomovie/models/user.dart';
import 'package:algomovie/providers/auth_provider.dart';
import 'package:algomovie/providers/movie_provider.dart';
import 'package:algomovie/providers/recommendation_provider.dart';
import 'package:flutter/foundation.dart';

class FakeAuthProvider extends AuthProvider {
  FakeAuthProvider({
    AuthStatus initialStatus = AuthStatus.authenticated,
    User? initialUser,
  })  : _status = initialStatus,
        _user = initialUser;

  AuthStatus _status;
  User? _user;
  String? _error;
  int loginCalls = 0;
  int registerCalls = 0;
  int logoutCalls = 0;
  int refreshCalls = 0;
  bool loginResult = true;
  bool registerResult = true;
  String? lastEmail;
  String? lastPassword;
  List<int>? lastGenres;

  @override
  AuthStatus get status => _status;

  @override
  User? get user => _user;

  @override
  String? get error => _error;

  @override
  Future<bool> login(String email, String password) async {
    loginCalls++;
    lastEmail = email;
    lastPassword = password;
    if (loginResult) {
      _status = AuthStatus.authenticated;
      _user ??= User(
        userId: 7,
        email: email,
        nickname: 'tester',
        ratingCount: 0,
        preferredGenres: [],
      );
    } else {
      _error = 'login failed';
    }
    notifyListeners();
    return loginResult;
  }

  @override
  Future<bool> register({
    required String email,
    required String password,
    required String nickname,
    required List<int> genres,
  }) async {
    registerCalls++;
    lastEmail = email;
    lastPassword = password;
    lastGenres = genres;
    if (registerResult) {
      _status = AuthStatus.authenticated;
      _user = User(
        userId: 7,
        email: email,
        nickname: nickname,
        ratingCount: 0,
        preferredGenres:
            genres.map((id) => Genre(genreId: id, name: 'Genre $id')).toList(),
      );
    } else {
      _error = 'register failed';
    }
    notifyListeners();
    return registerResult;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    _status = AuthStatus.unauthenticated;
    _user = null;
    notifyListeners();
  }

  @override
  Future<void> refreshProfile() async {
    refreshCalls++;
  }
}

class FakeMovieProvider extends MovieProvider {
  FakeMovieProvider({
    List<Movie> movies = const [],
    List<Movie> searchResults = const [],
    List<Movie> popularMovies = const [],
    List<String> genres = const ['All', 'Action', 'Drama'],
    String selectedGenre = 'All',
    Movie? currentMovie,
    List<Movie> similarMovies = const [],
  })  : _movies = List<Movie>.from(movies),
        _allMovies = List<Movie>.from(movies),
        _searchResults = List<Movie>.from(searchResults),
        _popularMovies = List<Movie>.from(popularMovies),
        _genres = List<String>.from(genres),
        _selectedGenre = selectedGenre,
        _currentMovie = currentMovie,
        _similarMovies = List<Movie>.from(similarMovies);

  List<Movie> _movies;
  final List<Movie> _allMovies;
  List<Movie> _searchResults;
  final List<Movie> _popularMovies;
  final List<String> _genres;
  String _selectedGenre;
  Movie? _currentMovie;
  final List<Movie> _similarMovies;
  bool _loading = false;
  final bool _searchLoading = false;
  final bool _popularLoading = false;
  String? _error;
  int feedbackCalls = 0;
  int wishlistCalls = 0;
  int ratingCalls = 0;
  int detailCalls = 0;
  String? lastFeedbackType;
  String? lastSearchQuery;
  double? lastScore;
  String? lastReview;
  String? lastGenre;
  String? lastCountry;
  String lastPopularPeriod = 'weekly';

  @override
  List<Movie> get movies => _movies;

  @override
  List<Movie> get searchResults => _searchResults;

  @override
  List<Movie> get popularMovies => _popularMovies;

  @override
  List<String> get genres => _genres;

  @override
  String get selectedGenre => _selectedGenre;

  @override
  bool get loading => _loading;

  @override
  bool get searchLoading => _searchLoading;

  @override
  bool get popularLoading => _popularLoading;

  @override
  String get popularPeriod => lastPopularPeriod;

  @override
  String? get error => _error;

  @override
  Movie? get currentMovie => _currentMovie;

  @override
  Future<void> loadGenres() async {}

  @override
  Future<void> loadMovies({String? genre, String? country}) async {
    lastGenre = genre;
    lastCountry = country;
    _movies = genre == null || genre == 'All' || genre == '전체'
        ? List<Movie>.from(_allMovies)
        : _allMovies.where((m) => m.genres.contains(genre)).toList();
    _loading = false;
    notifyListeners();
  }

  @override
  Future<void> loadPopularMovies({String period = 'weekly'}) async {
    lastPopularPeriod = period;
    notifyListeners();
  }

  @override
  Future<void> selectGenre(String genre) async {
    _selectedGenre = genre;
    _movies = _movies.where((m) => m.genres.contains(genre)).toList();
    notifyListeners();
  }

  @override
  Future<void> searchMovies(String query) async {
    lastSearchQuery = query;
    _searchResults = query.trim().isEmpty
        ? []
        : _movies
            .where((m) => m.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
    notifyListeners();
  }

  @override
  Future<Movie?> loadMovieDetail(int movieId) async {
    detailCalls++;
    if (_currentMovie?.movieId == movieId) {
      return _currentMovie;
    }
    _currentMovie = _movies.firstWhere(
      (m) => m.movieId == movieId,
      orElse: () => _similarMovies.firstWhere(
        (m) => m.movieId == movieId,
        orElse: () => Movie(
          movieId: movieId,
          title: 'Loaded Movie $movieId',
          genres: const [],
          avgRating: 0,
          ratingCount: 0,
        ),
      ),
    );
    return _currentMovie;
  }

  @override
  Future<List<Movie>> loadSimilarMovies(int movieId) async {
    return _similarMovies.where((m) => m.movieId != movieId).toList();
  }

  @override
  Future<Set<int>> fetchWishlistIds() async {
    return {};
  }

  @override
  Future<List<RatingItem>> fetchMyRatings() async {
    return [];
  }

  @override
  Future<bool> rateMovie(int movieId, double score, {String? review}) async {
    ratingCalls++;
    lastScore = score;
    lastReview = review;
    return true;
  }

  @override
  Future<bool> submitFeedback(int movieId, String type) async {
    feedbackCalls++;
    lastFeedbackType = type;
    return true;
  }

  @override
  Future<bool> toggleWishlist(int movieId) async {
    wishlistCalls++;
    return true;
  }

  @override
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
}

class FakeRecommendationProvider extends RecommendationProvider {
  FakeRecommendationProvider({
    List<Movie> recommendations = const [],
    Map<String, dynamic>? weights,
    bool fromCache = false,
  })  : _recommendations = List<Movie>.from(recommendations),
        _weights = weights,
        _fromCache = fromCache;

  List<Movie> _recommendations;
  final bool _loading = false;
  String? _error;
  Map<String, dynamic>? _weights;
  bool _fromCache;
  int loadCalls = 0;

  @override
  List<Movie> get recommendations => _recommendations;

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  @override
  Map<String, dynamic>? get weights => _weights;

  @override
  bool get fromCache => _fromCache;

  @override
  Future<void> loadRecommendations() async {
    loadCalls++;
    _recommendations = _recommendations.take(30).toList();
    notifyListeners();
  }

  void removeMovie(int movieId) {
    _recommendations =
        _recommendations.where((m) => m.movieId != movieId).toList();
    notifyListeners();
  }

  @override
  void clear() {
    _recommendations = [];
    _weights = null;
    _fromCache = false;
    notifyListeners();
  }
}

class FakeRepository extends ChangeNotifier {
  final List<Movie> wishlist = [];
  final List<Movie> recentHistory = [];

  void toggleWishlist(Movie movie) {
    final index = wishlist.indexWhere((m) => m.movieId == movie.movieId);
    if (index >= 0) {
      wishlist.removeAt(index);
    } else {
      wishlist.insert(0, movie);
    }
    notifyListeners();
  }

  void addHistory(Movie movie) {
    recentHistory.removeWhere((m) => m.movieId == movie.movieId);
    recentHistory.insert(0, movie);
    if (recentHistory.length > 10) {
      recentHistory.removeRange(10, recentHistory.length);
    }
    notifyListeners();
  }
}

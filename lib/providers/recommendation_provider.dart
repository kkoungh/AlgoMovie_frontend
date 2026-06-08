import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/movie.dart';

class RecommendationProvider extends ChangeNotifier {
  final _api = ApiService();

  List<Movie> _recommendations = [];
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _weights;
  bool _fromCache = false;
  bool _isNewUser = false;
  final Set<int> _votedMovieIds    = {};  // LIKE: 버튼 숨김
  final Set<int> _dislikedMovieIds = {};  // DISLIKE: 목록에서 제거

  List<Movie>           get recommendations => _recommendations;
  bool                  get loading         => _loading;
  String?               get error           => _error;
  Map<String, dynamic>? get weights         => _weights;
  bool                  get fromCache       => _fromCache;
  bool                  get isNewUser       => _isNewUser;
  Set<int>              get votedMovieIds   => _votedMovieIds;

  Future<void> loadRecommendations() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/recommendations');
      final list = data['recommendations'] as List<dynamic>? ?? [];
      _recommendations = list
          .whereType<Map<String, dynamic>>()
          .map((m) {
            try {
              return Movie.fromJson(m);
            } catch (e) {
              debugPrint('Movie.fromJson 실패: $e — $m');
              return null;
            }
          })
          .whereType<Movie>()
          .where((m) => !_dislikedMovieIds.contains(m.movieId))
          .toList();
      _weights   = data['weights']   as Map<String, dynamic>?;
      _fromCache = data['fromCache'] as bool? ?? false;
      _isNewUser = data['isNewUser'] as bool? ?? false;
    } catch (e) {
      _error = e.toString();
      debugPrint('loadRecommendations 에러: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void markVoted(int movieId) {
    _votedMovieIds.add(movieId);
    notifyListeners();
  }

  void removeRecommendation(int movieId) {
    _dislikedMovieIds.add(movieId);
    _recommendations.removeWhere((m) => m.movieId == movieId);
    notifyListeners();
  }

  void clear() {
    _recommendations = [];
    _weights  = null;
    _fromCache = false;
    notifyListeners();
  }
}

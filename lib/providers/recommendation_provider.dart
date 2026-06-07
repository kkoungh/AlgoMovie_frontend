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

  List<Movie>           get recommendations => _recommendations;
  bool                  get loading         => _loading;
  String?               get error           => _error;
  Map<String, dynamic>? get weights         => _weights;
  bool                  get fromCache       => _fromCache;
  bool                  get isNewUser       => _isNewUser;

  Future<void> loadRecommendations() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/recommendations');
      final list = data['recommendations'] as List<dynamic>? ?? [];
      _recommendations = list
          .map((m) => Movie.fromJson(m as Map<String, dynamic>))
          .toList();
      _weights   = data['weights']   as Map<String, dynamic>?;
      _fromCache = data['fromCache'] as bool? ?? false;
      _isNewUser = data['isNewUser'] as bool? ?? false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _recommendations = [];
    _weights  = null;
    _fromCache = false;
    notifyListeners();
  }
}

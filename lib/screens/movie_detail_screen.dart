import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/movie_provider.dart';
import '../providers/recommendation_provider.dart';
import '../models/movie.dart';
import '../widgets/star_rating.dart';
import '../widgets/movie_card.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  Movie? _movie;
  List<Movie> _similar = [];
  double _userRating = 0;
  final _reviewCtrl = TextEditingController();
  bool _ratingSubmitted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Movie && _movie == null) {
      _movie = arg;
      _loadDetail(arg.movieId);
    }
  }

  Future<void> _loadDetail(int id) async {
    final mp = context.read<MovieProvider>();
    final detail = await mp.loadMovieDetail(id);
    final similar = await mp.loadSimilarMovies(id);
    if (mounted) {
      setState(() {
        _movie = detail ?? _movie;
        _similar = similar;
      });
    }
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_userRating == 0) return;
    final ok = await context.read<MovieProvider>().rateMovie(
      _movie!.movieId,
      _userRating,
      review: _reviewCtrl.text.trim(),
    );
    if (ok && mounted) {
      setState(() => _ratingSubmitted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('평가가 저장되었습니다'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      context.read<RecommendationProvider>().loadRecommendations();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_movie == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMeta(),
                  const SizedBox(height: 16),
                  if (_movie!.overview != null && _movie!.overview!.isNotEmpty)
                    ...[
                      const Text(
                        '줄거리',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _movie!.overview!,
                        style: TextStyle(
                          color: Colors.grey[300],
                          height: 1.6,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  if (_movie!.director != null) ...[
                    _infoRow('감독', _movie!.director!),
                    const SizedBox(height: 8),
                  ],
                  if (_movie!.castMembers != null &&
                      _movie!.castMembers!.isNotEmpty) ...[
                    _infoRow(
                      '출연',
                      _movie!.castMembers!.take(5).join(', '),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 20),
                  _buildRatingSection(),
                  const SizedBox(height: 24),
                  if (_similar.isNotEmpty) _buildSimilarSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: const Color(0xFF121212),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_movie!.posterUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: _movie!.posterUrl,
                fit: BoxFit.cover,
              )
            else
              Container(color: const Color(0xFF2A2A2A)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xFF121212),
                  ],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _movie!.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_movie!.releaseYear != null) ...[
              Text(
                '${_movie!.releaseYear}',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              const SizedBox(width: 12),
            ],
            const Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
            const SizedBox(width: 4),
            Text(
              _movie!.avgRating.toStringAsFixed(1),
              style: TextStyle(color: Colors.grey[300], fontSize: 13),
            ),
            const SizedBox(width: 4),
            Text(
              '(${_movie!.ratingCount})',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _movie!.genres.map((g) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              g,
              style: TextStyle(color: Colors.grey[300], fontSize: 11),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[300], fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    if (_ratingSubmitted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A3A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[700]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green[400]),
            const SizedBox(width: 8),
            Text(
              '${_userRating.toStringAsFixed(1)}점으로 평가했습니다',
              style: TextStyle(color: Colors.green[300]),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내 평점',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: StarRating(
              initialRating: _userRating,
              onRatingUpdate: (v) => setState(() => _userRating = v),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '한줄 감상 (선택)',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _userRating > 0 ? _submitRating : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF3A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('평가 저장'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '비슷한 영화',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _similar.length,
            itemBuilder: (_, i) => MovieCard(
              movie: _similar[i],
              onTap: () {
                setState(() {
                  _movie = _similar[i];
                  _ratingSubmitted = false;
                  _userRating = 0;
                });
                _loadDetail(_similar[i].movieId);
              },
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/movie_provider.dart';
import '../providers/recommendation_provider.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    final mp = context.read<MovieProvider>();
    final rp = context.read<RecommendationProvider>();
    await Future.wait([
      mp.loadGenres(),
      mp.loadMovies(),
      rp.loadRecommendations(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFE50914),
          backgroundColor: const Color(0xFF1E1E1E),
          onRefresh: _loadAll,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildSearchBar(),
              _buildGenreFilter(),
              _buildHeroSpotlight(),
              _buildRecommendationSection(),
              _buildWeightDashboard(),
              _buildPopularSection(),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF121212),
      floating: true,
      snap: true,
      elevation: 0,
      title: const Text(
        'ALGOMOVIE',
        style: TextStyle(
          color: Color(0xFFE50914),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/search'),
        ),
        IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/mypage'),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/search'),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[500], size: 20),
              const SizedBox(width: 8),
              Text('영화 검색...', style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenreFilter() {
    return SliverToBoxAdapter(
      child: Consumer<MovieProvider>(
        builder: (_, mp, __) {
          return SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: mp.genres.length,
              itemBuilder: (_, i) {
                final g = mp.genres[i];
                final selected = mp.selectedGenre == g;
                return GestureDetector(
                  onTap: () => mp.selectGenre(g),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFE50914)
                          : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      g,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.grey[400],
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSpotlight() {
    return SliverToBoxAdapter(
      child: Consumer<RecommendationProvider>(
        builder: (_, rp, __) {
          if (rp.recommendations.isEmpty) return const SizedBox.shrink();
          final hero = rp.recommendations.first;
          return GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              '/movie',
              arguments: hero,
            ),
            child: Container(
              margin: const EdgeInsets.all(16),
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: hero.posterUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(hero.posterUrl),
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      )
                    : null,
                color: const Color(0xFF2A2A2A),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AI 추천 #1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hero.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hero.genres.isNotEmpty)
                      Text(
                        hero.genres.take(3).join(' · '),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationSection() {
    return SliverToBoxAdapter(
      child: Consumer<RecommendationProvider>(
        builder: (_, rp, __) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    const Text(
                      'AI 맞춤 추천',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (rp.fromCache)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3A1A),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green[700]!),
                        ),
                        child: Text(
                          'CACHE HIT',
                          style: TextStyle(
                            color: Colors.green[400],
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (rp.loading)
                const SizedBox(
                  height: 240,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFE50914)),
                  ),
                )
              else if (rp.recommendations.isEmpty)
                const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      '영화를 평가하면 맞춤 추천이 시작됩니다',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rp.recommendations.length,
                    itemBuilder: (_, i) {
                      final movie = rp.recommendations[i];
                      return MovieCard(
                        movie: movie,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/movie',
                          arguments: movie,
                        ),
                        onFeedback: (type) => _onFeedback(movie, type),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeightDashboard() {
    return SliverToBoxAdapter(
      child: Consumer<RecommendationProvider>(
        builder: (_, rp, __) {
          final w = rp.weights;
          if (w == null) return const SizedBox.shrink();

          final alpha = (w['alpha'] as num?)?.toDouble() ?? 0.0;
          final beta = (w['beta'] as num?)?.toDouble() ?? 0.0;
          final gamma = (w['gamma'] as num?)?.toDouble() ?? 0.0;
          final segment = w['segment'] as String? ?? '';

          return Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A4A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.tune,
                      color: Color(0xFF7C83FD),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '알고리즘 가중치',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A4A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        segment,
                        style: const TextStyle(
                          color: Color(0xFF7C83FD),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _weightRow('α  협업 필터링', alpha, const Color(0xFFE50914)),
                const SizedBox(height: 8),
                _weightRow('β  콘텐츠 기반', beta, const Color(0xFF4FC3F7)),
                const SizedBox(height: 8),
                _weightRow('γ  인기도', gamma, const Color(0xFF81C784)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _weightRow(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: const Color(0xFF2A2A2A),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(value * 100).toInt()}%',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPopularSection() {
    return SliverToBoxAdapter(
      child: Consumer<MovieProvider>(
        builder: (_, mp, __) {
          if (mp.loading) {
            return const SizedBox(
              height: 240,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFE50914)),
              ),
            );
          }
          if (mp.movies.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  '전체 영화',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: mp.movies.length,
                  itemBuilder: (_, i) {
                    final movie = mp.movies[i];
                    return MovieCard(
                      movie: movie,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/movie',
                        arguments: movie,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onFeedback(Movie movie, String type) async {
    final ok = await context.read<MovieProvider>().submitFeedback(
          movie.movieId,
          type,
        );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(type == 'LIKE' ? '👍 좋아요!' : '👎 싫어요'),
          duration: const Duration(seconds: 1),
          backgroundColor: type == 'LIKE'
              ? const Color(0xFF4CAF50)
              : const Color(0xFFE50914),
        ),
      );
      context.read<RecommendationProvider>().loadRecommendations();
    }
  }
}

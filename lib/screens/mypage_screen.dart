import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/rating.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key});

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _api = ApiService();

  List<RatingItem> _ratings  = [];
  List<Movie>      _wishlist = [];
  bool _ratingsLoading  = true;
  bool _wishlistLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadRatings();
    _loadWishlist();
    context.read<AuthProvider>().refreshProfile();
  }

  Future<void> _loadRatings() async {
    try {
      final data = await _api.get('/mypage/ratings') as List<dynamic>;
      if (mounted) {
        setState(() {
          _ratings = data
              .map((r) => RatingItem.fromJson(r as Map<String, dynamic>))
              .toList();
          _ratingsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _ratingsLoading = false);
    }
  }

  Future<void> _loadWishlist() async {
    try {
      final data = await _api.get('/wishlist') as List<dynamic>;
      if (mounted) {
        setState(() {
          _wishlist = data
              .map((m) => Movie.fromJson(m as Map<String, dynamic>))
              .toList();
          _wishlistLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _wishlistLoading = false);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        title: const Text('마이페이지'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFFE50914),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: '내 평가'),
            Tab(text: '위시리스트'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (user != null) _buildProfile(user),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildRatingsTab(),
                _buildWishlistTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1E1E1E),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFE50914),
            backgroundImage: user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child: user.profileImageUrl == null
                ? Text(
                    user.nickname.isNotEmpty
                        ? user.nickname[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _statChip('평가 ${user.ratingCount}편'),
                    const SizedBox(width: 8),
                    if (user.preferredGenres.isNotEmpty)
                      _statChip(
                        user.preferredGenres
                            .take(2)
                            .map((g) => g.name)
                            .join(' · '),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.grey[300], fontSize: 12),
      ),
    );
  }

  Widget _buildRatingsTab() {
    if (_ratingsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE50914)),
      );
    }
    if (_ratings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border, color: Colors.grey[700], size: 64),
            const SizedBox(height: 16),
            Text(
              '아직 평가한 영화가 없습니다',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _ratings.length,
      separatorBuilder: (_, __) => const Divider(
        color: Color(0xFF2A2A2A),
        height: 1,
      ),
      itemBuilder: (_, i) {
        final r = _ratings[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: r.movie.posterUrl.isNotEmpty
                    ? Image.network(
                        r.movie.posterUrl,
                        width: 50,
                        height: 75,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 50,
                        height: 75,
                        color: const Color(0xFF2A2A2A),
                        child: const Icon(
                          Icons.movie,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(5, (j) {
                        final full = j < r.score.floor();
                        final half = !full && j < r.score;
                        return Icon(
                          full
                              ? Icons.star
                              : half
                                  ? Icons.star_half
                                  : Icons.star_border,
                          color: const Color(0xFFFFD700),
                          size: 14,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    if (r.review != null && r.review!.isNotEmpty)
                      Text(
                        r.review!,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                r.score.toStringAsFixed(1),
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWishlistTab() {
    if (_wishlistLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE50914)),
      );
    }
    if (_wishlist.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border, color: Colors.grey[700], size: 64),
            const SizedBox(height: 16),
            Text(
              '위시리스트가 비어있습니다',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.55,
      ),
      itemCount: _wishlist.length,
      itemBuilder: (_, i) => MovieCard(
        movie: _wishlist[i],
        width: double.infinity,
        height: 160,
        onTap: () => Navigator.pushNamed(
          context,
          '/movie',
          arguments: _wishlist[i],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          '로그아웃',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '로그아웃 하시겠습니까?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Color(0xFFE50914)),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}

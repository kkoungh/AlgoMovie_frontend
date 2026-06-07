import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/movie.dart';
import '../providers/movie_provider.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _api = ApiService();

  // {addedAt: DateTime, movie: Movie}
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  int? _lastWishlistRevision;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final revision = context.watch<MovieProvider>().wishlistRevision;
    if (_lastWishlistRevision != null && revision != _lastWishlistRevision) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _load(showLoading: false));
    }
    _lastWishlistRevision = revision;
  }

  Future<void> _load({bool showLoading = true}) async {
    if (!mounted) return;
    if (showLoading) setState(() => _loading = true);
    try {
      final data = await _api.get('/mypage/wishlist') as Map<String, dynamic>;
      final list = data['wishlist'] as List<dynamic>;
      final items = list.map((item) {
        final map = item as Map<String, dynamic>;
        return {
          'addedAt': DateTime.tryParse(map['addedAt']?.toString() ?? '') ??
              DateTime.now(),
          'movie': Movie.fromJson(map['movie'] as Map<String, dynamic>),
        };
      }).toList();
      // 최근 추가한 순 정렬
      items.sort((a, b) =>
          (b['addedAt'] as DateTime).compareTo(a['addedAt'] as DateTime));
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _remove(Movie movie) async {
    try {
      final ok =
          await context.read<MovieProvider>().toggleWishlist(movie.movieId);
      if (!ok) {
        return;
      }
      if (mounted) {
        setState(() => _items.removeWhere(
            (e) => (e['movie'] as Movie).movieId == movie.movieId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${movie.title} 위시리스트에서 제거됨'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF252010),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _confirmRemove(Movie movie) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1608),
        title: const Text('위시리스트 제거', style: TextStyle(color: Colors.white)),
        content: Text('${movie.title}을(를) 제거하시겠습니까?',
            style: TextStyle(color: Colors.grey[400])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('제거', style: TextStyle(color: Color(0xFFF59E0B))),
          ),
        ],
      ),
    );
    if (ok == true) await _remove(movie);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0A07),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0A07),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('위시리스트',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            if (!_loading && _items.isNotEmpty)
              Text('${_items.length}편 · 최근 추가순',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : RefreshIndicator(
              color: const Color(0xFFF59E0B),
              backgroundColor: const Color(0xFF1A1608),
              onRefresh: _load,
              child: _items.isEmpty ? _buildEmpty() : _buildGrid(),
            ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border, color: Colors.grey[700], size: 72),
                const SizedBox(height: 16),
                Text('위시리스트가 비어있습니다',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                const SizedBox(height: 8),
                Text('영화 상세에서 북마크를 눌러 추가하세요',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.52,
      ),
      itemCount: _items.length,
      itemBuilder: (_, i) {
        final movie = _items[i]['movie'] as Movie;
        final addedAt = _items[i]['addedAt'] as DateTime;
        final label = _dateLabel(addedAt);
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/movie', arguments: movie),
          onLongPress: () => _confirmRemove(movie),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: movie.posterUrl.isNotEmpty
                      ? Image.network(
                          movie.posterUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                movie.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF252010),
        child: const Center(
            child: Icon(Icons.movie, color: Colors.grey, size: 28)),
      );

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return '오늘';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}주 전';
    return '${dt.month}월 ${dt.day}일';
  }
}

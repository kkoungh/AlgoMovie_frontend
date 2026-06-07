import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/rating.dart';
import '../models/movie.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key});

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  final _api = ApiService();

  List<RatingItem>           _ratings = [];
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic>?      _stats;
  bool       _ratingsLoading = true;
  bool       _historyLoading = true;
  bool       _statsLoading   = true;
  Uint8List? _pickedImageBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshProfile();
      _loadRatings();
      _loadHistory();
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    try {
      final data = await _api.get('/mypage/stats') as Map<String, dynamic>;
      if (mounted) setState(() { _stats = data; _statsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Future<void> _loadRatings() async {
    try {
      final data = await _api.get('/mypage/reviews') as Map<String, dynamic>;
      final list = data['reviews'] as List<dynamic>;
      if (mounted) {
        setState(() {
          _ratings = list.map((r) => RatingItem.fromJson(r as Map<String, dynamic>)).toList();
          _ratingsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _ratingsLoading = false);
    }
  }

  Future<void> _loadHistory() async {
    try {
      final data = await _api.get('/mypage/history') as Map<String, dynamic>;
      final list = data['history'] as List<dynamic>;
      if (mounted) {
        setState(() {
          _history = list.cast<Map<String, dynamic>>();
          _historyLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  // ── 프로필 수정 다이얼로그
  Future<void> _editProfile() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final nicknameCtrl = TextEditingController(text: user.nickname);
    Uint8List? dialogBytes = _pickedImageBytes;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('프로필 수정', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아바타 미리보기 + 사진 선택
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final xfile = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 400,
                    imageQuality: 80,
                  );
                  if (xfile == null) return;
                  final bytes = await xfile.readAsBytes();
                  setDialogState(() => dialogBytes = bytes);
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFFE50914),
                      backgroundImage: dialogBytes != null
                          ? MemoryImage(dialogBytes!)
                          : (user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!) as ImageProvider
                              : null),
                      child: (dialogBytes == null && user.profileImageUrl == null)
                          ? Text(user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE50914), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text('탭하여 사진 선택', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              const SizedBox(height: 16),
              TextField(
                controller: nicknameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '닉네임',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('취소', style: TextStyle(color: Colors.grey[400])),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  String? imageUrl = user.profileImageUrl;
                  if (dialogBytes != null) {
                    final b64 = base64Encode(dialogBytes!);
                    imageUrl = 'data:image/jpeg;base64,$b64';
                  }
                  await _api.patch('/users/me', {
                    'nickname': nicknameCtrl.text.trim(),
                    if (imageUrl != null) 'profileImageUrl': imageUrl,
                  });
                  if (mounted) {
                    setState(() => _pickedImageBytes = dialogBytes);
                    await context.read<AuthProvider>().refreshProfile();
                  }
                } catch (_) {}
              },
              child: const Text('저장', style: TextStyle(color: Color(0xFFE50914))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('로그아웃', style: TextStyle(color: Colors.white)),
        content: Text('로그아웃 하시겠습니까?', style: TextStyle(color: Colors.grey[400])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃', style: TextStyle(color: Color(0xFFE50914))),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await context.read<AuthProvider>().logout();
  }

  Future<void> _confirmWithdraw() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('회원탈퇴', style: TextStyle(color: Color(0xFFE50914))),
        content: Text(
          '탈퇴하면 모든 데이터가 삭제되며 복구할 수 없습니다.\n정말 탈퇴하시겠습니까?',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('탈퇴하기', style: TextStyle(color: Color(0xFFE50914))),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await _api.delete('/auth/withdraw');
        if (mounted) await context.read<AuthProvider>().logout();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('마이페이지',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFE50914),
        backgroundColor: const Color(0xFF1E1E1E),
        onRefresh: () async {
          await Future.wait([
            context.read<AuthProvider>().refreshProfile(),
            _loadRatings(),
            _loadHistory(),
          ]);
        },
        child: ListView(
          children: [
            if (user != null) _buildProfile(user),
            const SizedBox(height: 8),
            _buildStatsCard(),
            const SizedBox(height: 8),
            _buildSectionHeader('내 리뷰', '${_ratings.length}편'),
            _buildRatingsSection(),
            const SizedBox(height: 8),
            _buildSectionHeader('최근 본 영화', ''),
            _buildHistorySection(),
            const SizedBox(height: 24),
            _buildDangerZone(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(user) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFFE50914),
                backgroundImage: _pickedImageBytes != null
                    ? MemoryImage(_pickedImageBytes!) as ImageProvider
                    : (user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null),
                child: (_pickedImageBytes == null && user.profileImageUrl == null)
                    ? Text(
                        user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _editProfile,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE50914),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(user.nickname,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    GestureDetector(
                      onTap: _editProfile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('편집',
                            style: TextStyle(color: Color(0xFFE50914), fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(user.email, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statChip('평가 ${user.ratingCount}편'),
                    const SizedBox(width: 8),
                    _statChip(
                      user.preferredGenres.isNotEmpty
                          ? user.preferredGenres.take(2).map((g) => g.name).join(' · ')
                          : '장르 미설정',
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
      child: Text(label, style: TextStyle(color: Colors.grey[300], fontSize: 11)),
    );
  }

  Widget _buildStatsCard() {
    if (_statsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFE50914))),
      );
    }
    final s = _stats;
    if (s == null || (s['totalRatings'] as int? ?? 0) == 0) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.bar_chart, color: Color(0xFF7C83FD), size: 28),
            const SizedBox(width: 12),
            Text('영화를 평가하면 통계가 쌓입니다',
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      );
    }

    final total     = s['totalRatings']    as int;
    final avg       = (s['avgRatingGiven'] as num?)?.toDouble() ?? 0.0;
    final genres    = (s['genreDistribution'] as List<dynamic>? ?? []);
    final maxGenre  = genres.isNotEmpty
        ? (genres.map((g) => g['count'] as int).reduce((a, b) => a > b ? a : b))
        : 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.bar_chart, color: Color(0xFF7C83FD), size: 18),
            const SizedBox(width: 8),
            const Text('내 통계', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          // 평균 평점 + 평가수
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  Text(avg.toStringAsFixed(1),
                      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
                    return Icon(
                      i < avg.floor() ? Icons.star : (i < avg ? Icons.star_half : Icons.star_border),
                      color: const Color(0xFFFFD700), size: 14);
                  })),
                  const SizedBox(height: 4),
                  Text('평균 평점', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  Text('$total', style: const TextStyle(color: Color(0xFFE50914), fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Icon(Icons.movie_outlined, color: Color(0xFFE50914), size: 16),
                  const SizedBox(height: 4),
                  Text('평가한 영화', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ]),
              ),
            ),
          ]),
          if (genres.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('선호 장르', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...genres.take(5).map((g) {
              final name  = g['genre'] as String;
              final count = g['count'] as int;
              final ratio = count / maxGenre;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  SizedBox(
                    width: 72,
                    child: Text(name, style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF2A2A2A),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C83FD)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$count편', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ]),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String sub) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          if (sub.isNotEmpty)
            Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildRatingsSection() {
    if (_ratingsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Color(0xFFE50914)),
        ),
      );
    }
    if (_ratings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.star_border, color: Colors.grey[700], size: 48),
              const SizedBox(height: 12),
              Text('아직 평가한 영화가 없습니다',
                  style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _ratings.length,
      separatorBuilder: (_, __) => const Divider(color: Color(0xFF2A2A2A), height: 1),
      itemBuilder: (_, i) {
        final r = _ratings[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: r.movie.posterUrl.isNotEmpty
                    ? Image.network(r.movie.posterUrl,
                        width: 46, height: 68, fit: BoxFit.cover)
                    : Container(
                        width: 46, height: 68,
                        color: const Color(0xFF2A2A2A),
                        child: const Icon(Icons.movie, color: Colors.grey, size: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.movie.title,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(5, (j) {
                        final full = j < r.score.floor();
                        final half = !full && j < r.score;
                        return Icon(
                          full ? Icons.star : half ? Icons.star_half : Icons.star_border,
                          color: const Color(0xFFFFD700),
                          size: 14,
                        );
                      }),
                    ),
                    if (r.review != null && r.review!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(r.review!,
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
              Text(r.score.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistorySection() {
    if (_historyLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Color(0xFFE50914)),
        ),
      );
    }
    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.history, color: Colors.grey[700], size: 48),
              const SizedBox(height: 12),
              Text('최근 본 영화가 없습니다', style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _history.length,
        itemBuilder: (_, i) {
          final item = _history[i];
          final movie = item['movie'] as Map<String, dynamic>;
          final title = movie['title']?.toString() ?? '';
          final posterPath = movie['posterPath']?.toString();
          final movieId = int.tryParse(movie['movieId'].toString()) ?? 0;
          final posterUrl = posterPath != null && posterPath.isNotEmpty
              ? (posterPath.startsWith('http')
                  ? posterPath
                  : 'https://image.tmdb.org/t/p/w500$posterPath')
              : '';

          return GestureDetector(
            onTap: () {
              final m = Movie(
                movieId: movieId,
                title: title,
                genres: (movie['genres'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
                avgRating: (movie['avgRating'] as num?)?.toDouble() ?? 0.0,
                ratingCount: 0,
              );
              Navigator.pushNamed(context, '/movie', arguments: m);
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: posterUrl.isNotEmpty
                          ? Image.network(posterUrl,
                              width: 100, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _historyPlaceholder())
                          : _historyPlaceholder(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(title,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _historyPlaceholder() => Container(
        color: const Color(0xFF2A2A2A),
        child: const Center(child: Icon(Icons.movie, color: Colors.grey, size: 28)),
      );

  Widget _buildDangerZone() {
    return Column(
      children: [
        const Divider(color: Color(0xFF2A2A2A)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmWithdraw,
              icon: const Icon(Icons.person_remove, color: Color(0xFFE50914), size: 18),
              label: const Text('회원탈퇴', style: TextStyle(color: Color(0xFFE50914))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE50914)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

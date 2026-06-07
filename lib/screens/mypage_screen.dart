import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/movie_provider.dart';
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

  List<RatingItem> _ratings = [];
  List<Map<String, dynamic>> _history = [];
  bool _ratingsLoading = true;
  bool _historyLoading = true;
  Uint8List? _pickedImageBytes;
  int _ratingPageSize = 5;
  int _ratingPageIndex = 0;
  int? _lastRatingRevision;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshProfile();
      _loadRatings();
      _loadHistory();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final revision = context.watch<MovieProvider>().ratingRevision;
    if (_lastRatingRevision != null && revision != _lastRatingRevision) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.wait([
          context.read<AuthProvider>().refreshProfile(),
          _loadRatings(showLoading: false),
        ]);
      });
    }
    _lastRatingRevision = revision;
  }

  Future<void> _loadRatings({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _ratingsLoading = true);
    }
    try {
      final data = await _api.get('/mypage/reviews') as Map<String, dynamic>;
      final list = data['reviews'] as List<dynamic>;
      if (mounted) {
        setState(() {
          _ratings = list
              .map((r) => RatingItem.fromJson(r as Map<String, dynamic>))
              .toList();
          _clampRatingPage();
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
                              ? NetworkImage(user.profileImageUrl!)
                                  as ImageProvider
                              : null),
                      child:
                          (dialogBytes == null && user.profileImageUrl == null)
                              ? Text(
                                  user.nickname.isNotEmpty
                                      ? user.nickname[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold))
                              : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                          color: Color(0xFFE50914), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text('탭하여 사진 선택',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11)),
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
              child:
                  const Text('저장', style: TextStyle(color: Color(0xFFE50914))),
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
        content:
            Text('로그아웃 하시겠습니까?', style: TextStyle(color: Colors.grey[400])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('로그아웃', style: TextStyle(color: Color(0xFFE50914))),
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
            child:
                const Text('탈퇴하기', style: TextStyle(color: Color(0xFFE50914))),
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
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
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
            _buildRatingsHeader(),
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
                child:
                    (_pickedImageBytes == null && user.profileImageUrl == null)
                        ? Text(
                            user.nickname.isNotEmpty
                                ? user.nickname[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
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
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 14),
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
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                    GestureDetector(
                      onTap: _editProfile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('편집',
                            style: TextStyle(
                                color: Color(0xFFE50914), fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(user.email,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statChip('평가 ${user.ratingCount}편'),
                    const SizedBox(width: 8),
                    _statChip(
                      user.preferredGenres.isNotEmpty
                          ? user.preferredGenres
                              .take(2)
                              .map((g) => g.name)
                              .join(' · ')
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
      child:
          Text(label, style: TextStyle(color: Colors.grey[300], fontSize: 11)),
    );
  }

  Widget _buildSectionHeader(String title, String sub) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          if (sub.isNotEmpty)
            Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildRatingsHeader() {
    final start = _ratings.isEmpty ? 0 : _ratingPageIndex * _ratingPageSize + 1;
    final endCandidate = start + _ratingPageSize - 1;
    final end = endCandidate > _ratings.length ? _ratings.length : endCandidate;
    final sub = _ratings.isEmpty ? '0편' : '$start-$end/${_ratings.length}편';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          const Text('내 리뷰',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const Spacer(),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _ratingPageSize,
                dropdownColor: const Color(0xFF1E1E1E),
                icon:
                    Icon(Icons.expand_more, color: Colors.grey[400], size: 18),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5개')),
                  DropdownMenuItem(value: 10, child: Text('10개')),
                  DropdownMenuItem(value: 20, child: Text('20개')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _ratingPageSize = value;
                    _ratingPageIndex = 0;
                  });
                },
              ),
            ),
          ),
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
    final startIndex = _ratingPageIndex * _ratingPageSize;
    final endCandidate = startIndex + _ratingPageSize;
    final endIndex =
        endCandidate > _ratings.length ? _ratings.length : endCandidate;
    final visibleRatings = _ratings.sublist(startIndex, endIndex);
    final totalPages = _ratingTotalPages;

    return Column(
      children: [
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: visibleRatings.length,
          separatorBuilder: (_, __) =>
              const Divider(color: Color(0xFF2A2A2A), height: 1),
          itemBuilder: (_, i) {
            final r = visibleRatings[i];
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
                            width: 46,
                            height: 68,
                            color: const Color(0xFF2A2A2A),
                            child: const Icon(Icons.movie,
                                color: Colors.grey, size: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.movie.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
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
                        Text(
                          _formatDate(r.createdAt),
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                        if (r.review != null && r.review!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(r.review!,
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12),
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
        ),
        if (totalPages > 1) _buildRatingsPagination(totalPages),
      ],
    );
  }

  int get _ratingTotalPages {
    if (_ratings.isEmpty) return 1;
    return (_ratings.length + _ratingPageSize - 1) ~/ _ratingPageSize;
  }

  void _clampRatingPage() {
    final lastPage = _ratingTotalPages - 1;
    if (_ratingPageIndex > lastPage) {
      _ratingPageIndex = lastPage;
    }
    if (_ratingPageIndex < 0) {
      _ratingPageIndex = 0;
    }
  }

  Widget _buildRatingsPagination(int totalPages) {
    final canGoPrev = _ratingPageIndex > 0;
    final canGoNext = _ratingPageIndex < totalPages - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left),
            color: canGoPrev ? Colors.white : Colors.grey[700],
            onPressed:
                canGoPrev ? () => setState(() => _ratingPageIndex--) : null,
          ),
          Container(
            height: 32,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Text(
              '${_ratingPageIndex + 1} / $totalPages',
              style: TextStyle(color: Colors.grey[300], fontSize: 12),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_right),
            color: canGoNext ? Colors.white : Colors.grey[700],
            onPressed:
                canGoNext ? () => setState(() => _ratingPageIndex++) : null,
          ),
        ],
      ),
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
                genres: (movie['genres'] as List<dynamic>? ?? [])
                    .map((e) => e.toString())
                    .toList(),
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
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _historyPlaceholder())
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

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}.$month.$day';
  }

  Widget _historyPlaceholder() => Container(
        color: const Color(0xFF2A2A2A),
        child: const Center(
            child: Icon(Icons.movie, color: Colors.grey, size: 28)),
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
              icon: const Icon(Icons.person_remove,
                  color: Color(0xFFE50914), size: 18),
              label: const Text('회원탈퇴',
                  style: TextStyle(color: Color(0xFFE50914))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE50914)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

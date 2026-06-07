import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/movie_provider.dart';
import '../models/movie.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  static const _countries = [
    {'name': '전체',   'code': null, 'emoji': '🌍'},
    {'name': '한국',   'code': 'KR', 'emoji': '🇰🇷'},
    {'name': '미국',   'code': 'US', 'emoji': '🇺🇸'},
    {'name': '일본',   'code': 'JP', 'emoji': '🇯🇵'},
    {'name': '영국',   'code': 'GB', 'emoji': '🇬🇧'},
    {'name': '프랑스', 'code': 'FR', 'emoji': '🇫🇷'},
    {'name': '중국',   'code': 'CN', 'emoji': '🇨🇳'},
  ];

  int    _countryIdx = 0;
  String _selectedGenre = '전체';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovieProvider>().loadGenres();
      context.read<MovieProvider>().loadMovies();
    });
  }

  String? get _countryCode {
    final code = _countries[_countryIdx]['code'];
    return code?.toString();
  }

  void _selectCountry(int idx) {
    if (_countryIdx == idx) return;
    setState(() {
      _countryIdx = idx;
      _selectedGenre = '전체';
    });
    context.read<MovieProvider>().loadMovies(country: _countryCode);
  }

  void _selectGenre(String genre) {
    if (_selectedGenre == genre) return;
    setState(() => _selectedGenre = genre);
    context.read<MovieProvider>().loadMovies(
      genre: genre == '전체' ? null : genre,
      country: _countryCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0A07),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('카테고리',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
        ],
      ),
      body: Row(
        children: [
          // 1단계: 국가 패널
          _buildCountryPanel(),
          const VerticalDivider(color: Color(0xFF252010), width: 1),
          // 2단계: 장르 패널
          _buildGenrePanel(),
          const VerticalDivider(color: Color(0xFF252010), width: 1),
          // 3단계: 영화 그리드
          Expanded(child: _buildMovieGrid()),
        ],
      ),
    );
  }

  Widget _buildCountryPanel() {
    return SizedBox(
      width: 72,
      child: ListView.builder(
        itemCount: _countries.length,
        itemBuilder: (_, i) {
          final c       = _countries[i];
          final selected = _countryIdx == i;
          return _PanelItem(
            emoji:    c['emoji'] as String,
            label:    c['name']  as String,
            selected: selected,
            onTap:    () => _selectCountry(i),
          );
        },
      ),
    );
  }

  Widget _buildGenrePanel() {
    return SizedBox(
      width: 72,
      child: Consumer<MovieProvider>(
        builder: (_, mp, __) {
          final genres = ['전체', ...mp.genres.where((g) => g != '전체')];
          return ListView.builder(
            itemCount: genres.length,
            itemBuilder: (_, i) {
              final genre    = genres[i];
              final selected = _selectedGenre == genre;
              return _PanelItem(
                label:    genre,
                selected: selected,
                onTap:    () => _selectGenre(genre),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMovieGrid() {
    return Consumer<MovieProvider>(
      builder: (_, mp, __) {
        if (mp.loading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
        }
        if (mp.movies.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.movie_outlined, color: Colors.grey[700], size: 48),
                const SizedBox(height: 12),
                Text('영화가 없습니다', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            // 너비 140px 당 아이템 1개가 들어가도록 계산 (최소 2개, 최대 8개로 제한)
            int crossAxisCount = (constraints.maxWidth / 140).floor().clamp(2, 8);
            
            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.58,
              ),
              itemCount: mp.movies.length,
              itemBuilder: (_, i) {
                final movie = mp.movies[i];
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/movie', arguments: movie),
                  child: _MovieItem(movie: movie),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PanelItem extends StatelessWidget {
  final String?  emoji;
  final String   label;
  final bool     selected;
  final VoidCallback onTap;

  const _PanelItem({
    this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: selected ? const Color(0xFF1A1608) : const Color(0xFF141414),
        child: Stack(
          children: [
            if (selected)
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(width: 3, color: const Color(0xFFF59E0B)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (emoji != null) ...[
                      Text(emoji!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.grey[500],
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieItem extends StatelessWidget {
  final Movie movie;
  const _MovieItem({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: movie.posterUrl.isNotEmpty
                ? Image.network(movie.posterUrl,
                    width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
        ),
        const SizedBox(height: 4),
        Text(movie.title,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Row(children: [
          const Icon(Icons.star, color: Color(0xFFFFD700), size: 10),
          const SizedBox(width: 2),
          Text(movie.avgRating.toStringAsFixed(1),
              style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        ]),
      ],
    );
  }

  Widget _placeholder() => Container(
      color: const Color(0xFF252010),
      child: const Center(child: Icon(Icons.movie, color: Colors.grey, size: 28)));
}

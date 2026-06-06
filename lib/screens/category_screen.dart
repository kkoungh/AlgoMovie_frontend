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
  String? _selectedCountry;
  String _selectedGenre = '전체';

  static const _countries = [
    {'name': '한국', 'emoji': '🇰🇷', 'color': 0xFF1A3A5C},
    {'name': '미국', 'emoji': '🇺🇸', 'color': 0xFF3A1A1A},
    {'name': '일본', 'emoji': '🇯🇵', 'color': 0xFF3A1A2A},
    {'name': '영국', 'emoji': '🇬🇧', 'color': 0xFF1A2A3A},
    {'name': '프랑스', 'emoji': '🇫🇷', 'color': 0xFF1A1A3A},
    {'name': '중국', 'emoji': '🇨🇳', 'color': 0xFF3A2A1A},
    {'name': '기타', 'emoji': '🌍', 'color': 0xFF2A2A2A},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovieProvider>().loadGenres();
    });
  }

  Future<void> _selectCountry(String country) async {
    setState(() {
      _selectedCountry = country;
      _selectedGenre = '전체';
    });
    await context.read<MovieProvider>().loadMovies();
  }

  Future<void> _selectGenre(String genre) async {
    setState(() => _selectedGenre = genre);
    await context.read<MovieProvider>().loadMovies(
      genre: genre == '전체' ? null : genre,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        leading: _selectedCountry != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _selectedCountry = null;
                  _selectedGenre = '전체';
                }),
              )
            : null,
        title: Text(
          _selectedCountry != null ? _selectedCountry! : '카테고리',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
        ],
      ),
      body: _selectedCountry == null ? _buildCountryGrid() : _buildGenreMovies(),
    );
  }

  Widget _buildCountryGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '국가를 선택하세요',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              itemCount: _countries.length,
              itemBuilder: (_, i) {
                final c = _countries[i];
                return GestureDetector(
                  onTap: () => _selectCountry(c['name'] as String),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(c['color'] as int),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c['emoji'] as String, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          c['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreMovies() {
    return Column(
      children: [
        _buildGenreChips(),
        const Divider(color: Color(0xFF2A2A2A), height: 1),
        Expanded(child: _buildMovieGrid()),
      ],
    );
  }

  Widget _buildGenreChips() {
    return Consumer<MovieProvider>(
      builder: (_, mp, __) {
        final genres = mp.genres.isEmpty ? ['전체'] : mp.genres;
        return SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: genres.length,
            itemBuilder: (_, i) {
              final genre = genres[i];
              final selected = _selectedGenre == genre;
              return GestureDetector(
                onTap: () => _selectGenre(genre),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFE50914) : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                    border: selected ? null : Border.all(color: const Color(0xFF3A3A3A)),
                  ),
                  child: Text(
                    genre,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.grey[400],
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMovieGrid() {
    return Consumer<MovieProvider>(
      builder: (_, mp, __) {
        if (mp.loading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE50914)),
          );
        }
        if (mp.movies.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.movie_outlined, color: Colors.grey[700], size: 64),
                const SizedBox(height: 16),
                Text('해당 장르의 영화가 없습니다',
                    style: TextStyle(color: Colors.grey[500])),
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
            childAspectRatio: 0.58,
          ),
          itemCount: mp.movies.length,
          itemBuilder: (_, i) {
            final movie = mp.movies[i];
            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/movie', arguments: movie),
              child: _MovieGridItem(movie: movie),
            );
          },
        );
      },
    );
  }
}

class _MovieGridItem extends StatelessWidget {
  final Movie movie;
  const _MovieGridItem({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
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
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFD700), size: 10),
                    const SizedBox(width: 2),
                    Text(
                      movie.avgRating.toStringAsFixed(1),
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
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

  Widget _placeholder() => Container(
        color: const Color(0xFF2A2A2A),
        child: const Center(child: Icon(Icons.movie, color: Colors.grey, size: 30)),
      );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/movie_provider.dart';
import '../widgets/movie_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    context.read<MovieProvider>().clearSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '영화 제목, 감독, 배우 검색...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: InputBorder.none,
          ),
          onChanged: (v) =>
              context.read<MovieProvider>().searchMovies(v),
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                context.read<MovieProvider>().clearSearch();
              },
            ),
        ],
      ),
      body: Consumer<MovieProvider>(
        builder: (_, mp, __) {
          if (mp.searchLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            );
          }
          if (_ctrl.text.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, color: Colors.grey[700], size: 64),
                  const SizedBox(height: 16),
                  Text(
                    '영화를 검색해보세요',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            );
          }
          if (mp.searchResults.isEmpty) {
            return Center(
              child: Text(
                '"${_ctrl.text}" 검색 결과가 없습니다',
                style: TextStyle(color: Colors.grey[500]),
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
            itemCount: mp.searchResults.length,
            itemBuilder: (_, i) {
              final movie = mp.searchResults[i];
              return MovieCard(
                movie: movie,
                width: double.infinity,
                height: 160,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/movie',
                  arguments: movie,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

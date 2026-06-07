import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final Function(String)? onFeedback;
  final double width;
  final double height;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.onFeedback,
    this.width = 140,
    this.height = 180, // 🌟 [수정] 기본 포스터 이미지 높이를 210에서 180으로 줄여서 텍스트 공간(20~30px)을 확보합니다.
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  _buildPoster(),
                  if (onFeedback != null) _buildFeedbackButtons(),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // 🌟 [유지 및 안전장치] 제목 영역이 부모의 남은 세로 공간에 딱 맞춰 크기를 조절하도록 유지합니다.
            Flexible(
              child: Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 2), // 🌟 [추가] 제목과 출시일 사이 간격 미세 조정
            if (movie.releaseYear != null)
              Text(
                '${movie.releaseYear}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster() {
    if (movie.posterUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFF252010),
        child: const Icon(Icons.movie, color: Colors.grey, size: 40),
      );
    }
    return CachedNetworkImage(
      imageUrl: movie.posterUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: const Color(0xFF252010),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFF59E0B),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFF252010),
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
      ),
    ); // ⚡ 소괄호와 세미콜론으로 CachedNetworkImage를 완전히 닫아줍니다.
  } // ⚡ 마지막 중괄호로 _buildPoster() 함수를 완전히 닫아줍니다.

  Widget _buildFeedbackButtons() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _feedbackBtn(Icons.thumb_up, 'LIKE', const Color(0xFF4CAF50)),
            _feedbackBtn(Icons.thumb_down, 'DISLIKE', const Color(0xFFF59E0B)),
          ],
        ),
      ),
    );
  }

  Widget _feedbackBtn(IconData icon, String type, Color color) {
    return GestureDetector(
      onTap: () => onFeedback?.call(type),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
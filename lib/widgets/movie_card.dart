import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';

class MovieCard extends StatefulWidget {
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
    this.height = 180,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _feedbackGiven = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
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
                  if (widget.onFeedback != null && !_feedbackGiven)
                    _buildFeedbackButtons(),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                widget.movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 2),
            if (widget.movie.releaseYear != null)
              Text(
                '${widget.movie.releaseYear}',
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
    if (widget.movie.posterUrl.isEmpty) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: const Color(0xFF252010),
        child: const Icon(Icons.movie, color: Colors.grey, size: 40),
      );
    }
    return CachedNetworkImage(
      imageUrl: widget.movie.posterUrl,
      width: widget.width,
      height: widget.height,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        color: const Color(0xFF252010),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFF59E0B),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        width: widget.width,
        height: widget.height,
        color: const Color(0xFF252010),
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
      ),
    );
  }

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
      onTap: () {
        widget.onFeedback?.call(type);
        setState(() => _feedbackGiven = true);
      },
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

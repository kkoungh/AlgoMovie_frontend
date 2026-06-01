import 'movie.dart';

class RatingItem {
  final int ratingId;
  final double score;
  final String? review;
  final DateTime createdAt;
  final Movie movie;

  RatingItem({
    required this.ratingId,
    required this.score,
    this.review,
    required this.createdAt,
    required this.movie,
  });

  factory RatingItem.fromJson(Map<String, dynamic> json) => RatingItem(
        ratingId:  json['ratingId'] as int,
        score:     (json['score']   as num).toDouble(),
        review:    json['review']   as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        movie:     Movie.fromJson(json['movie'] as Map<String, dynamic>),
      );
}

class Movie {
  final int movieId;
  final String title;
  final List<String> genres;
  final String? director;
  final List<dynamic>? castMembers;
  final String? overview;
  final String? posterPath;
  final int? releaseYear;
  final double avgRating;
  final int ratingCount;
  final double? finalScore;

  Movie({
    required this.movieId,
    required this.title,
    required this.genres,
    this.director,
    this.castMembers,
    this.overview,
    this.posterPath,
    this.releaseYear,
    required this.avgRating,
    required this.ratingCount,
    this.finalScore,
  });

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
        movieId: json['movieId'] as int,
        title: json['title'] as String,
        genres: (json['genres'] as List<dynamic>? ?? [])
            .map((g) => g.toString())
            .toList(),
        director: json['director'] as String?,
        castMembers: json['castMembers'] as List<dynamic>?,
        overview: json['overview'] as String?,
        posterPath: json['posterPath'] as String?,
        releaseYear: json['releaseYear'] as int?,
        avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
        ratingCount: json['ratingCount'] as int? ?? 0,
        finalScore: (json['finalScore'] as num?)?.toDouble(),
      );

  String get posterUrl {
    if (posterPath == null || posterPath!.isEmpty) return '';
    if (posterPath!.startsWith('http')) return posterPath!;
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }
}

import 'package:algomovie/models/movie.dart';
import 'package:algomovie/models/rating.dart';
import 'package:algomovie/models/user.dart';

Movie mockMovie({
  int id = 1,
  String title = 'Interstellar',
  List<String> genres = const ['Sci-Fi', 'Drama'],
  String? posterPath,
  int? releaseYear = 2014,
  double avgRating = 4.8,
  int ratingCount = 120,
  double? finalScore,
}) {
  return Movie(
    movieId: id,
    title: title,
    genres: genres,
    director: 'Christopher Nolan',
    castMembers: const ['Matthew McConaughey', 'Anne Hathaway'],
    overview: 'A team travels through a wormhole in search of a new home.',
    posterPath: posterPath,
    releaseYear: releaseYear,
    avgRating: avgRating,
    ratingCount: ratingCount,
    finalScore: finalScore,
  );
}

List<Movie> mockMovies(int count) {
  return List.generate(
    count,
    (i) => mockMovie(
      id: i + 1,
      title: 'Movie ${i + 1}',
      genres: i.isEven ? const ['Action'] : const ['Drama'],
      avgRating: 5 - (i * 0.03),
      finalScore: 1 - (i * 0.01),
    ),
  );
}

User mockUser() {
  return User(
    userId: 7,
    email: 'tester@example.com',
    nickname: 'tester',
    ratingCount: 2,
    preferredGenres: [
      Genre(genreId: 1, name: 'Action'),
      Genre(genreId: 2, name: 'Drama'),
    ],
  );
}

List<RatingItem> mockRatingsNewestFirst() {
  return [
    RatingItem(
      ratingId: 2,
      score: 5,
      review: 'new review',
      createdAt: DateTime.parse('2026-06-02T10:00:00Z'),
      movie: mockMovie(id: 2, title: 'Newest Rated Movie'),
    ),
    RatingItem(
      ratingId: 1,
      score: 4,
      review: 'old review',
      createdAt: DateTime.parse('2026-06-01T10:00:00Z'),
      movie: mockMovie(id: 1, title: 'Older Rated Movie'),
    ),
  ];
}

const mockGenres = [
  {'genreId': 1, 'name': 'Action'},
  {'genreId': 2, 'name': 'Drama'},
  {'genreId': 3, 'name': 'Comedy'},
  {'genreId': 4, 'name': 'Sci-Fi'},
];

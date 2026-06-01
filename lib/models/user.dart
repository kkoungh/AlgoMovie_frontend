class User {
  final int userId;
  final String email;
  final String nickname;
  final String? profileImageUrl;
  final int ratingCount;
  final List<Genre> preferredGenres;

  User({
    required this.userId,
    required this.email,
    required this.nickname,
    this.profileImageUrl,
    required this.ratingCount,
    required this.preferredGenres,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        userId:          int.parse(json['userId'].toString()),
        email:           json['email']  as String,
        nickname:        json['nickname'] as String,
        profileImageUrl: json['profileImageUrl'] as String?,
        ratingCount:     json['ratingCount'] as int? ?? 0,
        preferredGenres: (json['preferredGenres'] as List<dynamic>? ?? [])
            .map((g) => Genre.fromJson(g as Map<String, dynamic>))
            .toList(),
      );
}

class Genre {
  final int genreId;
  final String name;
  Genre({required this.genreId, required this.name});
  factory Genre.fromJson(Map<String, dynamic> json) =>
      Genre(genreId: int.parse(json['genreId'].toString()), name: json['name'] as String);
}

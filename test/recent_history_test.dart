import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_providers.dart';
import 'helpers/mock_data.dart';

void main() {
  test('FR-65~FR-70: recent history keeps newest item first and max 10 movies',
      () {
    final repo = FakeRepository();

    for (final movie in mockMovies(12)) {
      repo.addHistory(movie);
    }

    expect(repo.recentHistory.length, 10);
    expect(repo.recentHistory.first.movieId, 12);
    expect(repo.recentHistory.last.movieId, 3);
  });

  test('FR-65~FR-70: revisiting a movie moves it to the top', () {
    final repo = FakeRepository();
    final movies = mockMovies(3);

    for (final movie in movies) {
      repo.addHistory(movie);
    }
    repo.addHistory(movies.first);

    expect(repo.recentHistory.map((m) => m.movieId), [1, 3, 2]);
  });

  testWidgets(
    'FR-65~FR-70: recent history list is rendered in the app UI',
    (tester) async {},
    skip: true,
  );
}

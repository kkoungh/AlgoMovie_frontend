import 'package:algomovie/screens/category_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_providers.dart';
import 'helpers/mock_data.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets('FR-78~FR-80: selecting a genre filters the movie list cards',
      (tester) async {
    final movieProvider = FakeMovieProvider(
      genres: const ['All', 'Action', 'Drama'],
      movies: [
        mockMovie(id: 1, title: 'Action Movie', genres: const ['Action']),
        mockMovie(id: 2, title: 'Drama Movie', genres: const ['Drama']),
      ],
    );

    await tester.pumpWidget(
      testApp(
        child: const CategoryScreen(),
        movieProvider: movieProvider,
        recommendationProvider: FakeRecommendationProvider(),
      ),
    );
    await pumpAppFrame(tester);

    await tester.tap(find.text('Drama'));
    await pumpAppFrame(tester);

    expect(movieProvider.lastGenre, 'Drama');
    expect(find.text('Drama Movie'), findsOneWidget);
    expect(find.text('Action Movie'), findsNothing);
  });

  testWidgets(
    'FR-78~FR-80: country -> genre -> movie category hierarchy is available',
    (tester) async {
      final movieProvider = FakeMovieProvider(
        genres: const ['전체', 'Action'],
        movies: [mockMovie(id: 10, title: 'Korean Action', genres: const ['Action'])],
      );

      await tester.pumpWidget(
        testApp(
          child: const CategoryScreen(),
          movieProvider: movieProvider,
          recommendationProvider: FakeRecommendationProvider(),
        ),
      );
      await pumpAppFrame(tester);

      await tester.tap(find.text('한국'));
      await pumpAppFrame(tester);
      await tester.tap(find.text('Action'));
      await pumpAppFrame(tester);

      expect(movieProvider.lastCountry, 'KR');
      expect(movieProvider.lastGenre, 'Action');
      expect(find.text('Korean Action'), findsOneWidget);
    },
  );
}

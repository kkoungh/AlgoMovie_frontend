import 'package:algomovie/screens/movie_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_providers.dart';
import 'helpers/mock_data.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets(
      'FR-24~FR-26: detail screen displays title, genre, director, cast, overview, year and rating',
      (tester) async {
    final movie = mockMovie(id: 1, title: 'Detail Movie');
    final movies = FakeMovieProvider(currentMovie: movie);

    await tester.pumpWidget(
      testApp(
        child: const MovieDetailScreen(),
        movieProvider: movies,
        recommendationProvider: FakeRecommendationProvider(),
      ),
    );

    await tester.pumpWidget(
      testApp(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/movie', arguments: movie),
            child: const Text('open'),
          ),
        ),
        movieProvider: movies,
        recommendationProvider: FakeRecommendationProvider(),
      ),
    );
    await tester.tap(find.text('open'));
    await pumpAppFrame(tester);

    expect(find.text('Detail Movie'), findsOneWidget);
    expect(find.text('Sci-Fi'), findsOneWidget);
    expect(find.text('Drama'), findsOneWidget);
    expect(find.text('Christopher Nolan'), findsOneWidget);
    expect(find.textContaining('Matthew'), findsOneWidget);
    expect(find.textContaining('wormhole'), findsOneWidget);
    expect(find.text('2014'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
  });

  testWidgets(
      'FR-50~FR-51: similar list excludes current movie and can switch detail content',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final current = mockMovie(id: 1, title: 'Current Movie');
    final similar = mockMovie(id: 2, title: 'Similar Movie');
    final movies = FakeMovieProvider(
      currentMovie: current,
      similarMovies: [current, similar],
    );

    await tester.pumpWidget(
      testApp(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/movie', arguments: current),
            child: const Text('open'),
          ),
        ),
        movieProvider: movies,
        recommendationProvider: FakeRecommendationProvider(),
      ),
    );
    await tester.tap(find.text('open'));
    await pumpAppFrame(tester);

    expect(find.text('Similar Movie'), findsOneWidget);
    expect(find.text('Current Movie'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Similar Movie'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Similar Movie'));
    await pumpAppFrame(tester);

    expect(find.text('Similar Movie'), findsWidgets);
  });
}

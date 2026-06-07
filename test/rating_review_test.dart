import 'package:algomovie/screens/movie_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_providers.dart';
import 'helpers/mock_data.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets(
      'FR-52~FR-55: rating save is disabled until a star rating is selected',
      (tester) async {
    final movie = mockMovie();
    final movies = FakeMovieProvider(currentMovie: movie);

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
    await tester.pumpAndSettle();

    final saveButton =
        tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(saveButton.onPressed, isNull);
  });

  testWidgets(
      'FR-52~FR-54: review text can be empty while rating state is handled by detail screen',
      (tester) async {
    final movie = mockMovie();
    final movies = FakeMovieProvider(currentMovie: movie);

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
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 3);
  });
}

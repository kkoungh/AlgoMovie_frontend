import 'package:algomovie/widgets/star_rating.dart';
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
    await pumpAppFrame(tester);

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
    await pumpAppFrame(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 3);
  });

  testWidgets('FR-52~FR-55, FR-62~FR-64: detail saves rating and toggles wishlist',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final movie = mockMovie();
    final movies = FakeMovieProvider(currentMovie: movie);
    final recommendations = FakeRecommendationProvider();

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
        recommendationProvider: recommendations,
      ),
    );
    await tester.tap(find.text('open'));
    await pumpAppFrame(tester);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await pumpAppFrame(tester);
    expect(movies.wishlistCalls, 1);
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.byType(StarRating)));
    await pumpAppFrame(tester);
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('평가 저장'));
    await pumpAppFrame(tester);

    expect(movies.ratingCalls, 1);
    expect(movies.lastReview, '');
    expect(recommendations.loadCalls, 1);
  });
}

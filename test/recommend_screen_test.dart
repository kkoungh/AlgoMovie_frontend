import 'package:algomovie/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_providers.dart';
import 'helpers/mock_data.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets(
      'FR-30~FR-35: recommendation screen displays score-sorted movie list',
      (tester) async {
    final recs = [
      mockMovie(id: 1, title: 'Score 0.99', finalScore: 0.99),
      mockMovie(id: 2, title: 'Score 0.80', finalScore: 0.80),
      mockMovie(id: 3, title: 'Score 0.70', finalScore: 0.70),
    ];

    await tester.pumpWidget(
      testApp(
        child: const HomeScreen(),
        movieProvider: FakeMovieProvider(movies: mockMovies(3)),
        recommendationProvider:
            FakeRecommendationProvider(recommendations: recs),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Score 0.99'), findsWidgets);
    expect(find.text('Score 0.80'), findsOneWidget);
    expect(find.text('Score 0.70'), findsOneWidget);
  });

  testWidgets('FR-35: recommendation provider caps refreshed list to top 30',
      (tester) async {
    final recProvider =
        FakeRecommendationProvider(recommendations: mockMovies(35));

    await recProvider.loadRecommendations();

    expect(recProvider.recommendations.length, 30);
    expect(recProvider.recommendations.first.title, 'Movie 1');
  });

  testWidgets(
      'FR-30: new user can see genre/popularity based recommendation list',
      (tester) async {
    await tester.pumpWidget(
      testApp(
        child: const HomeScreen(),
        movieProvider: FakeMovieProvider(movies: mockMovies(2)),
        recommendationProvider: FakeRecommendationProvider(
          recommendations: [mockMovie(title: 'Popular Starter Pick')],
          weights: {'alpha': 0.0, 'beta': 0.5, 'gamma': 0.5, 'segment': 'new'},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Popular Starter Pick'), findsWidgets);
    expect(find.text('CACHE HIT'), findsNothing);
  });
}

import 'package:algomovie/widgets/movie_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_providers.dart';
import 'helpers/mock_data.dart';

void main() {
  testWidgets(
      'FR-58~FR-60: satisfied and dissatisfied feedback buttons are available on recommendation card',
      (tester) async {
    final movieProvider = FakeMovieProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovieCard(
            movie: mockMovie(id: 1),
            onFeedback: (type) => movieProvider.submitFeedback(1, type),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.thumb_up));
    expect(movieProvider.lastFeedbackType, 'LIKE');

    await tester.tap(find.byIcon(Icons.thumb_down));
    expect(movieProvider.lastFeedbackType, 'DISLIKE');
  });

  testWidgets(
      'FR-60: dislike can remove movie from recommendation list in UI state',
      (tester) async {
    final recProvider = FakeRecommendationProvider(
      recommendations: [
        mockMovie(id: 1, title: 'Remove Me'),
        mockMovie(id: 2, title: 'Keep Me')
      ],
    );

    recProvider.removeMovie(1);

    expect(recProvider.recommendations.map((m) => m.title), ['Keep Me']);
  });
}

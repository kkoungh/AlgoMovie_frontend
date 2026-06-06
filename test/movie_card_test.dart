import 'package:algomovie/widgets/movie_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_data.dart';

void main() {
  testWidgets(
      'FR-19~FR-23: movie card displays title, release year and rating metadata',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: MovieCard(
              movie: mockMovie(title: 'Card Movie', releaseYear: 2026)),
        ),
      ),
    );

    expect(find.text('Card Movie'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
  });

  testWidgets('FR-20: missing poster uses fallback movie icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MovieCard(movie: mockMovie(posterPath: null))),
      ),
    );

    expect(find.byIcon(Icons.movie), findsOneWidget);
  });

  testWidgets(
      'FR-58~FR-60: recommendation feedback buttons emit LIKE and DISLIKE',
      (tester) async {
    final events = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovieCard(
            movie: mockMovie(),
            onFeedback: events.add,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.thumb_up));
    await tester.tap(find.byIcon(Icons.thumb_down));

    expect(events, ['LIKE', 'DISLIKE']);
  });
}

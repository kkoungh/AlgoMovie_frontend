import 'package:algomovie/screens/search_screen.dart';
import 'package:algomovie/widgets/movie_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_providers.dart';
import 'helpers/mock_data.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets('FR-75~FR-76: search results are shown by title relevance',
      (tester) async {
    final movies = FakeMovieProvider(
      movies: [
        mockMovie(id: 1, title: 'Inception'),
        mockMovie(id: 2, title: 'Interstellar'),
      ],
    );

    await tester.pumpWidget(
        testApp(child: const SearchScreen(), movieProvider: movies));
    await tester.enterText(find.byType(EditableText), 'incep');
    await tester.pumpAndSettle();

    expect(movies.lastSearchQuery, 'incep');
    expect(find.text('Inception'), findsOneWidget);
    expect(find.text('Interstellar'), findsNothing);
  });

  testWidgets(
      'FR-77: empty search result displays an empty state message containing the query',
      (tester) async {
    final movies = FakeMovieProvider(movies: [mockMovie(title: 'Inception')]);

    await tester.pumpWidget(
        testApp(child: const SearchScreen(), movieProvider: movies));
    await tester.enterText(find.byType(EditableText), 'missing');
    await tester.pumpAndSettle();

    expect(find.textContaining('"missing"'), findsOneWidget);
  });

  testWidgets('FR-83: tapping a search result navigates to movie detail route',
      (tester) async {
    final movies =
        FakeMovieProvider(movies: [mockMovie(id: 1, title: 'Inception')]);

    await tester.pumpWidget(
        testApp(child: const SearchScreen(), movieProvider: movies));
    await tester.enterText(find.byType(EditableText), 'Inception');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(MovieCard));
    final cardTopLeft = tester.getTopLeft(find.byType(MovieCard));
    await tester.tapAt(cardTopLeft + const Offset(24, 24));
    await tester.pumpAndSettle();

    expect(find.text('Christopher Nolan'), findsOneWidget);
  });
}

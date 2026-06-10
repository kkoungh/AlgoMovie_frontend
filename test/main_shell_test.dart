import 'package:algomovie/screens/category_screen.dart';
import 'package:algomovie/screens/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_providers.dart';
import 'helpers/mock_data.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets('FR-84: bottom navigation switches to category and wishlist tabs',
      (tester) async {
    await tester.pumpWidget(
      testApp(
        child: const MainShell(),
        authProvider: FakeAuthProvider(initialUser: mockUser()),
        movieProvider: FakeMovieProvider(movies: mockMovies(2)),
        recommendationProvider: FakeRecommendationProvider(
          recommendations: [mockMovie(title: 'Shell Recommendation')],
        ),
      ),
    );
    await pumpAppFrame(tester);

    expect(find.text('ALGOMOVIE'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await pumpAppFrame(tester);
    expect(find.byType(CategoryScreen), findsOneWidget);
    expect(find.text('카테고리'), findsWidgets);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await pumpAppFrame(tester);
    expect(find.text('위시리스트'), findsWidgets);
  });
}

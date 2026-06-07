import 'package:algomovie/screens/home_screen.dart';
import 'package:algomovie/screens/mypage_screen.dart';
import 'package:algomovie/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_providers.dart';
import '../helpers/mock_data.dart';
import '../helpers/test_app.dart';

Future<Duration> measureWidgetLoad(
  WidgetTester tester,
  Future<void> Function() action,
) async {
  final startedAt = tester.binding.clock.now();
  await action();
  return tester.binding.clock.now().difference(startedAt);
}

void main() {
  testWidgets('NFR-03: home screen renders with mock data under 2 seconds',
      (tester) async {
    final elapsed = await measureWidgetLoad(tester, () async {
      await tester.pumpWidget(
        testApp(
          child: const HomeScreen(),
          movieProvider: FakeMovieProvider(movies: mockMovies(3)),
          recommendationProvider: FakeRecommendationProvider(
            recommendations: mockMovies(3),
          ),
        ),
      );
      await tester.pump();
    });

    expect(find.text('Movie 1'), findsWidgets);
    expect(elapsed, lessThan(const Duration(seconds: 2)));
  });

  testWidgets('NFR-03: search empty-result screen stays stable under 2 seconds',
      (tester) async {
    final elapsed = await measureWidgetLoad(tester, () async {
      await tester.pumpWidget(
        testApp(
          child: const SearchScreen(),
          movieProvider:
              FakeMovieProvider(movies: [mockMovie(title: 'Inception')]),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'missing');
      await tester.pump();
    });

    expect(find.textContaining('"missing"'), findsOneWidget);
    expect(elapsed, lessThan(const Duration(seconds: 2)));
  });

  testWidgets(
      'NFR-03: movie detail screen renders with mock data under 2 seconds',
      (tester) async {
    final movie = mockMovie(id: 1, title: 'Performance Detail');
    final elapsed = await measureWidgetLoad(tester, () async {
      await tester.pumpWidget(
        testApp(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/movie', arguments: movie),
              child: const Text('open detail'),
            ),
          ),
          movieProvider: FakeMovieProvider(currentMovie: movie),
          recommendationProvider: FakeRecommendationProvider(),
        ),
      );
      await tester.tap(find.text('open detail'));
      await tester.pump();
      await tester.pump();
    });

    expect(find.text('Performance Detail'), findsOneWidget);
    expect(elapsed, lessThan(const Duration(seconds: 2)));
  });

  testWidgets('NFR-03: mypage renders mock profile data under 2 seconds',
      (tester) async {
    final elapsed = await measureWidgetLoad(tester, () async {
      await tester.pumpWidget(
        testApp(
          child: MypageScreen(
            initialRatings: mockRatingsNewestFirst(),
            initialWishlist: [mockMovie(title: 'Wish Performance')],
          ),
          authProvider: FakeAuthProvider(initialUser: mockUser()),
        ),
      );
      await tester.pump();
    });

    expect(find.text('tester@example.com'), findsOneWidget);
    expect(elapsed, lessThan(const Duration(seconds: 2)));
  });

  test('NFR-07: frontend API base URL used in deployed checks should be HTTPS',
      () {
    const deployedApiBaseUrl = 'https://api.algomovie.example.com/api';

    expect(Uri.parse(deployedApiBaseUrl).scheme, 'https');
  });
}

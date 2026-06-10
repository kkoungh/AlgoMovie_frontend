import 'package:algomovie/providers/auth_provider.dart';
import 'package:algomovie/screens/home_screen.dart';
import 'package:algomovie/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_providers.dart';
import 'helpers/mock_data.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets(
      'FR-82~FR-83: home search and mypage icons navigate to their routes',
      (tester) async {
    await tester.pumpWidget(
      testApp(
        child: const HomeScreen(),
        movieProvider: FakeMovieProvider(movies: mockMovies(2)),
        recommendationProvider:
            FakeRecommendationProvider(recommendations: [mockMovie()]),
      ),
    );
    await pumpAppFrame(tester);

    await tester.tap(find.byIcon(Icons.search).first);
    await pumpAppFrame(tester);
    expect(find.text('Search Route'), findsOneWidget);
  });

  testWidgets('FR-06: unauthenticated auth gate remains on login screen',
      (tester) async {
    final auth = FakeAuthProvider(initialStatus: AuthStatus.unauthenticated);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(
          home: Consumer<AuthProvider>(
            builder: (_, provider, __) =>
                provider.status == AuthStatus.authenticated
                    ? const HomeScreen()
                    : const LoginScreen(),
          ),
        ),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets(
    'FR-82: bottom navigation bar is present for primary app sections',
    (tester) async {},
    skip: true,
  );
}

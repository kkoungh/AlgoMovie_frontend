import 'package:algomovie/providers/auth_provider.dart';
import 'package:algomovie/screens/home_screen.dart';
import 'package:algomovie/screens/login_screen.dart';
import 'package:algomovie/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_providers.dart';
import 'helpers/mock_data.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets('FR-01~FR-03: login requires valid email and password',
      (tester) async {
    final auth = FakeAuthProvider(initialStatus: AuthStatus.unauthenticated);
    await tester
        .pumpWidget(testApp(child: const LoginScreen(), authProvider: auth));

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(auth.loginCalls, 0);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('FR-04~FR-05: successful login moves auth gate to home screen',
      (tester) async {
    final auth = FakeAuthProvider(initialStatus: AuthStatus.unauthenticated);
    await tester.pumpWidget(
      testApp(
        child: ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: Consumer<AuthProvider>(
            builder: (_, provider, __) =>
                provider.status == AuthStatus.authenticated
                    ? const HomeScreen()
                    : const LoginScreen(),
          ),
        ),
        movieProvider: FakeMovieProvider(movies: mockMovies(2)),
        recommendationProvider: FakeRecommendationProvider(),
      ),
    );

    await tester.enterText(
        find.byType(TextFormField).at(0), 'tester@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.byType(ElevatedButton));
    await pumpAppFrame(tester);

    expect(auth.loginCalls, 1);
    expect(find.text('ALGOMOVIE'), findsOneWidget);
  });

  testWidgets(
      'FR-01~FR-03: register screen validates email, password and nickname',
      (tester) async {
    final auth = FakeAuthProvider();
    await tester.pumpWidget(
      testApp(
        child: const RegisterScreen(initialGenres: mockGenres),
        authProvider: auth,
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'bad-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'a');
    await tester.enterText(find.byType(TextFormField).at(2), 'short');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(auth.registerCalls, 0);
  });

  testWidgets('FR-06: unauthenticated protected entry shows login route',
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
    expect(find.byType(HomeScreen), findsNothing);
  });
}

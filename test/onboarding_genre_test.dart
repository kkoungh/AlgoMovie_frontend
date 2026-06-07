import 'package:algomovie/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_providers.dart';
import 'helpers/mock_data.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets(
      'FR-27~FR-29: preferred genre selection is visible during onboarding',
      (tester) async {
    final auth = FakeAuthProvider();
    await tester.pumpWidget(
      testApp(
        child: const RegisterScreen(initialGenres: mockGenres),
        authProvider: auth,
      ),
    );

    expect(find.text('Action'), findsOneWidget);
    expect(find.text('Drama'), findsOneWidget);
    expect(find.text('Comedy'), findsOneWidget);
  });

  testWidgets('FR-29: less than 3 selected genres blocks registration',
      (tester) async {
    final auth = FakeAuthProvider();
    await tester.pumpWidget(
      testApp(
        child: const RegisterScreen(initialGenres: mockGenres),
        authProvider: auth,
      ),
    );

    await tester.enterText(
        find.byType(TextFormField).at(0), 'tester@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'tester');
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.tap(find.text('Action'));
    await tester.tap(find.text('Drama'));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(auth.registerCalls, 0);
  });

  testWidgets('FR-29: 3 selected genres allows registration submit',
      (tester) async {
    final auth = FakeAuthProvider();
    await tester.pumpWidget(
      testApp(
        child: const RegisterScreen(initialGenres: mockGenres),
        authProvider: auth,
      ),
    );

    await tester.enterText(
        find.byType(TextFormField).at(0), 'tester@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'tester');
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.tap(find.text('Action'));
    await tester.tap(find.text('Drama'));
    await tester.tap(find.text('Comedy'));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(auth.registerCalls, 1);
    expect(auth.lastGenres, [1, 2, 3]);
  });
}

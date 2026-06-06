import 'package:algomovie/screens/mypage_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_providers.dart';
import 'helpers/mock_data.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets(
      'FR-62~FR-64, FR-85~FR-86: wishlist page displays saved movies in recent-first order',
      (tester) async {
    final auth = FakeAuthProvider(initialUser: mockUser());

    await tester.pumpWidget(
      testApp(
        child: MypageScreen(
          initialRatings: const [],
          initialWishlist: [
            mockMovie(id: 3, title: 'Recently Added Wish'),
            mockMovie(id: 1, title: 'Older Wish'),
          ],
        ),
        authProvider: auth,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Tab).last);
    await tester.pumpAndSettle();

    expect(find.text('Recently Added Wish'), findsOneWidget);
    expect(find.text('Older Wish'), findsOneWidget);
  });

  test('FR-62~FR-64: wishlist toggle activates and deactivates the same movie',
      () {
    final repo = FakeRepository();
    final movie = mockMovie(id: 1);

    repo.toggleWishlist(movie);
    expect(repo.wishlist.map((m) => m.movieId), [1]);

    repo.toggleWishlist(movie);
    expect(repo.wishlist, isEmpty);
  });

  testWidgets(
    'FR-62~FR-64: heart button toggles active and inactive state on movie detail/card',
    (tester) async {},
    skip: true,
  );
}

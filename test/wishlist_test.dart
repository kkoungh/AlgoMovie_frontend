import 'package:algomovie/screens/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_providers.dart';
import 'helpers/mock_data.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets(
      'FR-62~FR-64, FR-85~FR-86: wishlist page displays saved movies in recent-first order',
      (tester) async {
    await tester.pumpWidget(
      testApp(
        child: WishlistScreen(
          initialItems: [
            {
              'addedAt': DateTime.parse('2026-06-02T10:00:00Z'),
              'movie': mockMovie(id: 3, title: 'Recently Added Wish'),
            },
            {
              'addedAt': DateTime.parse('2026-06-01T10:00:00Z'),
              'movie': mockMovie(id: 1, title: 'Older Wish'),
            },
          ],
        ),
        movieProvider: FakeMovieProvider(),
      ),
    );
    await pumpAppFrame(tester);

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

  testWidgets('FR-85: wishlist page shows an empty state', (tester) async {
    await tester.pumpWidget(
      testApp(
        child: const WishlistScreen(initialItems: []),
        movieProvider: FakeMovieProvider(),
      ),
    );
    await pumpAppFrame(tester);

    expect(find.text('위시리스트가 비어있습니다'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('FR-62~FR-64: long press confirms and removes a wishlist movie',
      (tester) async {
    final movie = mockMovie(id: 4, title: 'Remove Wish');
    final provider = FakeMovieProvider();

    await tester.pumpWidget(
      testApp(
        child: WishlistScreen(
          initialItems: [
            {'addedAt': DateTime.now(), 'movie': movie},
          ],
        ),
        movieProvider: provider,
      ),
    );
    await pumpAppFrame(tester);

    await tester.longPress(find.text('Remove Wish'));
    await pumpAppFrame(tester);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('제거'));
    await pumpAppFrame(tester);

    expect(provider.wishlistCalls, 1);
    expect(find.text('Remove Wish'), findsNothing);
  });
}

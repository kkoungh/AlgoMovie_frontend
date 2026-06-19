import 'package:algomovie/screens/mypage_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_providers.dart';
import 'helpers/mock_data.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets('FR-07: mypage displays email, nickname and profile initials',
      (tester) async {
    final auth = FakeAuthProvider(initialUser: mockUser());

    await tester.pumpWidget(
      testApp(
        child: MypageScreen(
          initialRatings: mockRatingsNewestFirst(),
          initialWishlist: [mockMovie(title: 'Wish Movie')],
          initialStats: const {
            'totalRatings': 2,
            'avgRatingGiven': 4.5,
            'genreDistribution': [
              {'genre': 'Drama', 'count': 2},
              {'genre': 'Action', 'count': 1},
            ],
          },
        ),
        authProvider: auth,
      ),
    );
    await pumpAppFrame(tester);

    expect(find.text('tester'), findsOneWidget);
    expect(find.text('tester@example.com'), findsOneWidget);
    expect(find.text('T'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('Drama'), findsOneWidget);
  });

  testWidgets(
      'FR-10~FR-11: rating history displays title, score and review in newest-first order',
      (tester) async {
    final auth = FakeAuthProvider(initialUser: mockUser());

    await tester.pumpWidget(
      testApp(
        child: MypageScreen(
          initialRatings: mockRatingsNewestFirst(),
          initialWishlist: const [],
          initialStats: const {'totalRatings': 0},
        ),
        authProvider: auth,
      ),
    );
    await pumpAppFrame(tester);

    expect(find.text('Newest Rated Movie'), findsOneWidget);
    expect(find.text('Older Rated Movie'), findsOneWidget);
    expect(find.text('new review'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);

    final newerTop = tester.getTopLeft(find.text('Newest Rated Movie')).dy;
    final olderTop = tester.getTopLeft(find.text('Older Rated Movie')).dy;
    expect(newerTop, lessThan(olderTop));
  });

  testWidgets('FR-08~FR-09: profile edit and photo change UI exists',
      (tester) async {
    final auth = FakeAuthProvider(initialUser: mockUser());

    await tester.pumpWidget(
      testApp(
        child: const MypageScreen(
          initialRatings: [],
          initialWishlist: [],
          initialStats: {'totalRatings': 0},
        ),
        authProvider: auth,
      ),
    );
    await pumpAppFrame(tester);

    await tester.tap(find.byIcon(Icons.camera_alt).first);
    await pumpAppFrame(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsWidgets);
  });

  testWidgets('FR-17: account withdrawal confirmation popup is shown',
      (tester) async {
    final auth = FakeAuthProvider(initialUser: mockUser());

    await tester.pumpWidget(
      testApp(
        child: const MypageScreen(
          initialRatings: [],
          initialWishlist: [],
          initialStats: {'totalRatings': 0},
        ),
        authProvider: auth,
      ),
    );
    await pumpAppFrame(tester);

    await tester.scrollUntilVisible(
      find.text('회원탈퇴'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('회원탈퇴'));
    await pumpAppFrame(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('?'), findsWidgets);
  });
}

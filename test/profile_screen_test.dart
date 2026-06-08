import 'package:algomovie/screens/mypage_screen.dart';
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
        ),
        authProvider: auth,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('tester'), findsOneWidget);
    expect(find.text('tester@example.com'), findsOneWidget);
    expect(find.text('T'), findsOneWidget);
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
        ),
        authProvider: auth,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Newest Rated Movie'), findsOneWidget);
    expect(find.text('Older Rated Movie'), findsOneWidget);
    expect(find.text('new review'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);

    final newerTop = tester.getTopLeft(find.text('Newest Rated Movie')).dy;
    final olderTop = tester.getTopLeft(find.text('Older Rated Movie')).dy;
    expect(newerTop, lessThan(olderTop));
  });

  testWidgets(
    'FR-08~FR-09: profile edit and photo change/delete UI exists',
    (tester) async {},
    skip: true,
  );

  testWidgets(
    'FR-17: account withdrawal confirmation popup is shown',
    (tester) async {},
    skip: true,
  );
}

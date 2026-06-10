import 'package:algomovie/providers/auth_provider.dart';
import 'package:algomovie/providers/movie_provider.dart';
import 'package:algomovie/providers/recommendation_provider.dart';
import 'package:algomovie/screens/movie_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<void> pumpAppFrame(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 300));
}

Widget testApp({
  required Widget child,
  AuthProvider? authProvider,
  MovieProvider? movieProvider,
  RecommendationProvider? recommendationProvider,
}) {
  return MultiProvider(
    providers: [
      if (authProvider != null)
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      if (movieProvider != null)
        ChangeNotifierProvider<MovieProvider>.value(value: movieProvider),
      if (recommendationProvider != null)
        ChangeNotifierProvider<RecommendationProvider>.value(
          value: recommendationProvider,
        ),
    ],
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: child,
      routes: {
        '/movie': (_) => const MovieDetailScreen(),
        '/login': (_) =>
            const Scaffold(body: Center(child: Text('Login Route'))),
        '/home': (_) => const Scaffold(body: Center(child: Text('Home Route'))),
        '/search': (_) =>
            const Scaffold(body: Center(child: Text('Search Route'))),
        '/mypage': (_) =>
            const Scaffold(body: Center(child: Text('Mypage Route'))),
      },
    ),
  );
}

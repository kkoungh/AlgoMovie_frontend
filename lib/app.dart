import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/movie_provider.dart';
import 'providers/recommendation_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_shell.dart';
import 'screens/mypage_screen.dart';
import 'screens/movie_detail_screen.dart';
import 'screens/search_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MovieProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
      ],
      child: MaterialApp(
        title: 'AlgoMovie',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0C0A07),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFF59E0B),
            secondary: Color(0xFFF59E0B),
            surface: Color(0xFF1A1608),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0C0A07),
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        ),
        home: const _AuthGate(),
        routes: {
          '/login':    (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home':     (_) => const MainShell(),
          '/search':   (_) => const SearchScreen(),
          '/movie':    (_) => const MovieDetailScreen(),
          '/mypage':   (_) => const MypageScreen(),
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        switch (auth.status) {
          case AuthStatus.authenticated:
            return const MainShell();
          case AuthStatus.unauthenticated:
            return const LoginScreen();
          case AuthStatus.unknown:
            return const SplashScreen();
        }
      },
    );
  }
}

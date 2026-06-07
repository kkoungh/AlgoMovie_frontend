import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await context.read<AuthProvider>().checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0A07),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ALGOMOVIE',
              style: TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI 기반 영화 추천',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Color(0xFFF59E0B)),
          ],
        ),
      ),
    );
  }
}

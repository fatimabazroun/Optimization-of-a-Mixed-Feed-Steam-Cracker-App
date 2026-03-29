import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() {
  runApp(const CrackerIQApp());
}

class CrackerIQApp extends StatelessWidget {
  const CrackerIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrackerIQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
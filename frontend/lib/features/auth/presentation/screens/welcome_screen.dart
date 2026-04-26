import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../workspace/presentation/screens/main_shell.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  String _firstName = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _loadName();
  }

  Future<void> _loadName() async {
    final attrs = await AuthService.fetchUserAttributes();
    final fullName = attrs['name'] ?? '';
    final firstName = fullName.trim().split(' ').first;
    if (mounted) setState(() => _firstName = firstName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: const Image(
                      image: AssetImage('assets/images/Transparent_logo.png'),
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _firstName.isNotEmpty ? 'Hi, $_firstName!' : 'Hi there!',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: context.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text('Welcome to CrackerIQ',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.cyan),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Text(
                    'Explore steam cracking scenarios, compare KPIs, and make data-driven decisions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: context.textSecondary, height: 1.5),
                  ),
                  const Spacer(),
                  GradientButton(
                    text: 'Get Started',
                    gradient: AppColors.tealGradient,
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const MainShell(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 400),
                      ),
                      (route) => false,
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

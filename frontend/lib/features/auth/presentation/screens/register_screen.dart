import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import 'login_screen.dart';
import 'verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    setState(() => _submitted = true);
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              VerificationScreen(email: _emailController.text),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Form(
              key: _formKey,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios, size: 16, color: AppColors.textMedium),
                        SizedBox(width: 4),
                        Text('Back', style: AppTextStyles.body),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text('Create Account', style: AppTextStyles.heading2),
                  const SizedBox(height: 6),
                  const Text('Begin your journey to CrackerIQ', style: AppTextStyles.body),
                  const SizedBox(height: 32),

                  // Full name
                  AppTextField(
                    hint: 'Full Name',
                    controller: _nameController,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Full name is required';
                      if (v.trim().length < 2) return 'Enter a valid name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Email
                  AppTextField(
                    hint: 'Email address',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password
                  AppTextField(
                    hint: 'Password',
                    isPassword: true,
                    controller: _passwordController,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'At least 6 characters required';
                      if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least one number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Confirm password
                  AppTextField(
                    hint: 'Confirm Password',
                    isPassword: true,
                    controller: _confirmPasswordController,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please confirm your password';
                      if (v != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),
                  GradientButton(text: 'Get Started', onPressed: _onGetStarted),
                  const SizedBox(height: 20),

                  const Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ', style: AppTextStyles.body),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const LoginScreen(),
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration: const Duration(milliseconds: 300),
                          ),
                        ),
                        child: const Text('Log In', style: AppTextStyles.link),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
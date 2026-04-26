import 'package:flutter/material.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import 'login_screen.dart';

class ForgotPasswordNewScreen extends StatefulWidget {
  final String email;
  final String code;

  const ForgotPasswordNewScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ForgotPasswordNewScreen> createState() => _ForgotPasswordNewScreenState();
}

class _ForgotPasswordNewScreenState extends State<ForgotPasswordNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _submitted = false;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    setState(() {
      _submitted = true;
      _errorMessage = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await AuthService.confirmResetPassword(
        email: widget.email,
        code: widget.code,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
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
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back_ios, size: 16, color: context.textSecondary),
                        SizedBox(width: 4),
                        Text('Back', style: TextStyle(fontSize: 14, color: context.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_outline,
                          color: AppColors.cyan, size: 36),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('New Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.textPrimary)),
                  const SizedBox(height: 6),
                  Text(
                    'Choose a strong password for your account.',
                    style: TextStyle(fontSize: 14, color: context.textSecondary),
                  ),
                  const SizedBox(height: 36),
                  AppTextField(
                    hint: 'New password',
                    isPassword: true,
                    controller: _passwordController,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 8) return 'At least 8 characters';
                      if (!RegExp(r'\d').hasMatch(v)) return 'Include at least one number';
                      if (!RegExp(r'[!@#\$&*~^%]').hasMatch(v)) {
                        return 'Include at least one special character';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    hint: 'Confirm new password',
                    isPassword: true,
                    controller: _confirmController,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please confirm your password';
                      if (v != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: Colors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(fontSize: 13, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                  GradientButton(
                    text: _loading ? 'Resetting…' : 'Reset Password',
                    onPressed: _loading ? null : _resetPassword,
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

import 'package:flutter/material.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import 'forgot_password_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _submitted = true;
      _errorMessage = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await AuthService.resetPassword(_emailController.text.trim());
      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => ForgotPasswordCodeScreen(
            email: _emailController.text.trim(),
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
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
                      child: const Icon(Icons.lock_reset_outlined,
                          color: AppColors.cyan, size: 36),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Forgot Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.textPrimary)),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your email and we\'ll send you a 6-digit reset code.',
                    style: TextStyle(fontSize: 14, color: context.textSecondary),
                  ),
                  const SizedBox(height: 36),
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
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
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
                    text: _loading ? 'Sending…' : 'Send Code',
                    onPressed: _loading ? null : _sendCode,
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

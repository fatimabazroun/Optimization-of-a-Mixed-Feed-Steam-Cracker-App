import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/widgets/gradient_button.dart';
import 'welcome_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final bool isSignUp;

  const VerificationScreen({
    super.key,
    required this.email,
    this.isSignUp = true,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _hasError = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    for (final f in _focusNodes) {
      f.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    setState(() => _hasError = false);
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  bool get _isComplete => _controllers.every((c) => c.text.isNotEmpty);

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _onContinue() async {
    if (!_isComplete) {
      setState(() => _hasError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Please enter the complete 6-digit code'),
            ],
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      if (widget.isSignUp) {
        await AuthService.confirmSignUp(
          email: widget.email,
          code: _code,
        );
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const WelcomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyError(e)),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onResend() async {
    try {
      await AuthService.resendSignUpCode(widget.email);
      for (final c in _controllers) { c.clear(); }
      setState(() => _hasError = false);
      _focusNodes[0].requestFocus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Code resent successfully'),
          backgroundColor: AppColors.cyan,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyError(e)),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
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

                const Spacer(),

                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mark_email_unread_outlined,
                            color: AppColors.cyan, size: 36),
                      ),
                      const SizedBox(height: 24),

                      const Text('Enter Verification\nCode',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading2),
                      const SizedBox(height: 12),
                      Text(
                        "We've sent a 6-digit code to\n${widget.email}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMedium,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 6-digit OTP inputs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (i) {
                          final isFocused = _focusNodes[i].hasFocus;
                          final hasValue = _controllers[i].text.isNotEmpty;
                          final showError = _hasError && !hasValue;

                          return Container(
                            width: 46, height: 56,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: AppColors.inputBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: showError
                                    ? Colors.red
                                    : isFocused
                                        ? AppColors.cyan
                                        : hasValue
                                            ? AppColors.midTone
                                            : AppColors.inputBorder,
                                width: isFocused || showError ? 2.0 : 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkBase,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                              ),
                              onChanged: (v) => _onChanged(v, i),
                            ),
                          );
                        }),
                      ),

                      if (_hasError) ...[
                        const SizedBox(height: 12),
                        const Text('Please fill in all 6 digits',
                            style: TextStyle(fontSize: 12, color: Colors.red)),
                      ],

                      const SizedBox(height: 32),

                      GestureDetector(
                        onTap: _onResend,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.inputBorder),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text('Resend Code', style: AppTextStyles.body),
                        ),
                      ),

                      const SizedBox(height: 24),
                      GradientButton(
                        text: _loading ? 'Verifying…' : 'Continue',
                        onPressed: _loading ? null : _onContinue,
                      ),
                    ],
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

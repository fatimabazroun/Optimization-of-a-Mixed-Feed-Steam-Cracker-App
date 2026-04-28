import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/glass_toast.dart';
import 'welcome_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final String? password;
  final bool isSignUp;

  const VerificationScreen({
    super.key,
    required this.email,
    this.password,
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
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    setState(() => _hasError = false);
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  bool get _isComplete => _controllers.every((c) => c.text.isNotEmpty);

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _onContinue() async {
    if (!_isComplete) {
      setState(() => _hasError = true);
      showGlassToast(
        context,
        'Please enter the complete 6-digit code.',
        type: GlassToastType.error,
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
        // Auto sign-in after confirmation so the session exists immediately
        if (widget.password != null) {
          await AuthService.signIn(
            email: widget.email,
            password: widget.password!,
          );
        }
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
      showGlassToast(
        context,
        AuthService.friendlyError(e),
        type: GlassToastType.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onResend() async {
    try {
      await AuthService.resendSignUpCode(widget.email);
      for (final c in _controllers) {
        c.clear();
      }
      setState(() => _hasError = false);
      _focusNodes[0].requestFocus();
      if (!mounted) return;
      showGlassToast(
        context,
        'Code resent successfully.',
        type: GlassToastType.success,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      showGlassToast(
        context,
        AuthService.friendlyError(e),
        type: GlassToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive box width: fills available horizontal space minus padding and gaps
    final boxSize = ((screenWidth - 56 - 48) / 6).clamp(38.0, 52.0);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_ios,
                          size: 16, color: context.textSecondary),
                      SizedBox(width: 4),
                      Text('Back',
                          style: TextStyle(
                              fontSize: 14, color: context.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mark_email_unread_outlined,
                            color: AppColors.cyan, size: 36),
                      ),
                      const SizedBox(height: 24),

                      Text('Enter Verification\nCode',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary)),
                      const SizedBox(height: 12),
                      Text(
                        "We've sent a 6-digit code to\n${widget.email}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 6-digit OTP inputs – responsive width
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (i) {
                          final isFocused = _focusNodes[i].hasFocus;
                          final hasValue = _controllers[i].text.isNotEmpty;
                          final showError = _hasError && !hasValue;

                          return Container(
                            width: boxSize,
                            height: boxSize * 1.2,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
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
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              maxLength: 1,
                              style: TextStyle(
                                fontSize: boxSize * 0.42,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (v) => _onChanged(v, i),
                            ),
                          );
                        }),
                      ),

                      if (_hasError) ...[
                        const SizedBox(height: 12),
                        Text('Please fill in all 6 digits',
                            style: TextStyle(fontSize: 12, color: Colors.red)),
                      ],

                      const SizedBox(height: 40),

                      GestureDetector(
                        onTap: _onResend,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: context.inputBorder),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text('Resend Code',
                              style: TextStyle(
                                  fontSize: 14, color: context.textSecondary)),
                        ),
                      ),

                      const SizedBox(height: 20),
                      GradientButton(
                        text: _loading ? 'Verifying…' : 'Continue',
                        onPressed: _loading ? null : _onContinue,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

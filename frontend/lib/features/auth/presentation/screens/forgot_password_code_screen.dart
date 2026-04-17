import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/widgets/gradient_button.dart';
import 'forgot_password_new_screen.dart';

class ForgotPasswordCodeScreen extends StatefulWidget {
  final String email;

  const ForgotPasswordCodeScreen({super.key, required this.email});

  @override
  State<ForgotPasswordCodeScreen> createState() => _ForgotPasswordCodeScreenState();
}

class _ForgotPasswordCodeScreenState extends State<ForgotPasswordCodeScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _hasError = false;
  bool _loading = false;
  String? _errorMessage;
  bool _resendSent = false;

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
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
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

  void _onContinue() {
    if (!_isComplete) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please fill in all 6 digits';
      });
      return;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ForgotPasswordNewScreen(
          email: widget.email,
          code: _code,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _onResend() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _resendSent = false;
    });
    try {
      await AuthService.resetPassword(widget.email);
      if (!mounted) return;
      for (final c in _controllers) { c.clear(); }
      setState(() {
        _hasError = false;
        _resendSent = true;
      });
      _focusNodes[0].requestFocus();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boxSize = ((screenWidth - 56 - 48) / 6).clamp(38.0, 52.0);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
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
                      const Text(
                        'Enter Verification\nCode',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading2,
                      ),
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
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              maxLength: 1,
                              style: TextStyle(
                                fontSize: boxSize * 0.42,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkBase,
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

                      const SizedBox(height: 14),
                      if (_errorMessage != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 15, color: Colors.red),
                            const SizedBox(width: 5),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: 13, color: Colors.red),
                            ),
                          ],
                        )
                      else if (_resendSent)
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 15, color: AppColors.cyan),
                            SizedBox(width: 5),
                            Text(
                              'Code resent successfully',
                              style: TextStyle(fontSize: 13, color: AppColors.cyan),
                            ),
                          ],
                        )
                      else
                        const SizedBox(height: 18),

                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: _loading ? null : _onResend,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.inputBorder),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            _loading ? 'Resending…' : 'Resend Code',
                            style: AppTextStyles.body,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GradientButton(
                        text: 'Continue',
                        onPressed: _onContinue,
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

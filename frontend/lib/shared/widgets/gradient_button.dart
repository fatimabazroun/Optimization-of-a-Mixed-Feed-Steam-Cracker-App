import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final double? width;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient,
    this.width,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _ctrl!.addListener(() {
      setState(() => _scale = 1.0 - (_ctrl!.value * 0.07));
    });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (widget.onPressed != null) _ctrl?.forward(from: 0.0);
  }

  void _onTapUp(_) {
    widget.onPressed?.call();
    _ctrl?.animateBack(0.0, curve: Curves.elasticOut);
  }

  void _onTapCancel() => _ctrl?.animateBack(0.0, curve: Curves.elasticOut);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Opacity(
        opacity: widget.onPressed == null ? 0.55 : 1.0,
        child: Transform.scale(
          scale: _scale,
          child: SizedBox(
            width: widget.width ?? double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: widget.gradient ?? AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(widget.text, style: AppTextStyles.buttonText),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
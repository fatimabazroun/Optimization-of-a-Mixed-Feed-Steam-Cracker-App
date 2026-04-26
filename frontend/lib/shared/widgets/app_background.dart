import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(gradient: context.bgGradient),
        ),
        Positioned(
          top: -40,
          left: -40,
          child: _BreathingBlob(size: 320, color: const Color(0xFF4A5FA8),
            opacityMin: 0.12, opacityMax: 0.22,
            scaleMin: 0.95, scaleMax: 1.05,
            duration: const Duration(seconds: 9)),
        ),
        Positioned(
          bottom: -40,
          right: -40,
          child: _BreathingBlob(size: 300, color: const Color(0xFF5DBFC9),
            opacityMin: 0.10, opacityMax: 0.20,
            scaleMin: 0.96, scaleMax: 1.04,
            duration: const Duration(seconds: 11)),
        ),
        Positioned(
          top: 260,
          right: -30,
          child: _BreathingBlob(size: 200, color: const Color(0xFF6B7BC9),
            opacityMin: 0.08, opacityMax: 0.15,
            scaleMin: 0.97, scaleMax: 1.03,
            duration: const Duration(seconds: 7)),
        ),
        child,
      ],
    );
  }
}

class _BreathingBlob extends StatefulWidget {
  final double size;
  final Color color;
  final double opacityMin, opacityMax, scaleMin, scaleMax;
  final Duration duration;

  const _BreathingBlob({
    required this.size, required this.color,
    required this.opacityMin, required this.opacityMax,
    required this.scaleMin, required this.scaleMax,
    required this.duration,
  });

  @override
  State<_BreathingBlob> createState() => _BreathingBlobState();
}

class _BreathingBlobState extends State<_BreathingBlob> {
  bool _forward = true;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _forward ? 0.0 : 1.0, end: _forward ? 1.0 : 0.0),
      duration: widget.duration,
      curve: Curves.easeInOut,
      onEnd: () { if (mounted) setState(() => _forward = !_forward); },
      builder: (_, t, __) {
        final opacity = widget.opacityMin + (widget.opacityMax - widget.opacityMin) * t;
        final scale   = widget.scaleMin  + (widget.scaleMax  - widget.scaleMin)  * t;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                widget.color.withValues(alpha: opacity),
                Colors.transparent,
              ]),
            ),
          ),
        );
      },
    );
  }
}

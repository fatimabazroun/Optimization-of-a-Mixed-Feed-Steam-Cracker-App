import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

enum GlassToastType { success, error, info }

void showGlassToast(
  BuildContext context,
  String message, {
  GlassToastType type = GlassToastType.info,
}) {
  final overlay = Overlay.of(context);

  final Color accent = switch (type) {
    GlassToastType.success => const Color(0xFF27AE60),
    GlassToastType.error   => const Color(0xFFE74C3C),
    GlassToastType.info    => const Color(0xFF5DBFC9),
  };

  final IconData icon = switch (type) {
    GlassToastType.success => Icons.check_circle_outline,
    GlassToastType.error   => Icons.error_outline,
    GlassToastType.info    => Icons.info_outline,
  };

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _GlassToastWidget(
      message: message,
      accent: accent,
      icon: icon,
      onDismiss: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

class _GlassToastWidget extends StatefulWidget {
  final String message;
  final Color accent;
  final IconData icon;
  final VoidCallback onDismiss;

  const _GlassToastWidget({
    required this.message,
    required this.accent,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_GlassToastWidget> createState() => _GlassToastWidgetState();
}

class _GlassToastWidgetState extends State<_GlassToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      await _ctrl.reverse();
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.82),
                        widget.accent.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: widget.accent.withValues(alpha: 0.30),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accent.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(widget.icon, color: widget.accent, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A2555),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

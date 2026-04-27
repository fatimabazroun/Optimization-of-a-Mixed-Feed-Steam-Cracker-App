import 'package:flutter/material.dart';

class AppColors {
  // Brand palette — same in both modes
  static const Color darkBase    = Color(0xFF1A2555);
  static const Color primaryBlue = Color(0xFF2D3B7D);
  static const Color midTone     = Color(0xFF4A5FA8);
  static const Color lightBlue   = Color(0xFF7B93D4);
  static const Color highlight   = Color(0xFFA8C0F0);

  static const Color cyan        = Color(0xFF5DBFC9);
  static const Color cyanDark    = Color(0xFF4AA5AF);
  static const Color purple      = Color(0xFF6B7BC9);
  static const Color purpleDark  = Color(0xFF5566B3);
  static const Color deepPurple  = Color(0xFF5D5FA8);
  static const Color deepPurpleDark = Color(0xFF4A4B8F);

  // Static light-mode fallbacks (used in const contexts)
  static const Color scaffoldBg  = Color(0xFFF0F2F8);
  static const Color cardBg      = Colors.white;
  static const Color inputBg     = Color(0xFFF0F4FF);
  static const Color inputBorder = Color(0xFFD0DCEF);
  static const Color textDark    = Color(0xFF1A2555);
  static const Color textMedium  = Color(0xFF4A5FA8);
  static const Color textLight   = Color(0xFF7B93D4);
  static const Color accentBlue  = Color(0xFF2D3B7D);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4A5FA8), Color(0xFF2D3B7D)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF5DBFC9), Color(0xFF4A5FA8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFE8EEF8), Color(0xFFF5F7FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [Color(0xFF141B30), Color(0xFF1A2240)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ── BuildContext color extension ────────────────────────────────────────────
extension CrackXTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Surfaces
  Color get surface        => isDark ? const Color(0xFF1E2640) : Colors.white;
  Color get surfaceModal   => isDark ? const Color(0xFF1E2640).withValues(alpha: 0.97) : Colors.white.withValues(alpha: 0.95);
  Color get surfaceVariant => isDark ? const Color(0xFF252D45) : const Color(0xFFF5F8FF);
  Color get inputBg        => isDark ? const Color(0xFF252D45) : AppColors.inputBg;
  Color get inputBorder    => isDark ? const Color(0xFF3A4560) : AppColors.inputBorder;

  // Text
  Color get textPrimary   => isDark ? Colors.white            : AppColors.darkBase;
  Color get textSecondary => isDark ? const Color(0xFF9FB3D8) : AppColors.textMedium;
  Color get textTertiary  => isDark ? const Color(0xFF6B85B5) : AppColors.textLight;

  // Shadows
  Color get cardShadow => isDark
      ? Colors.black.withValues(alpha: 0.30)
      : AppColors.primaryBlue.withValues(alpha: 0.07);

  // Background gradient
  LinearGradient get bgGradient =>
      isDark ? AppColors.darkBackgroundGradient : AppColors.backgroundGradient;

  // Nav bar glass
  Color get navBarBg     => isDark ? const Color(0xFF1A2240).withValues(alpha: 0.90) : Colors.white.withValues(alpha: 0.75);
  Color get navBarBorder => isDark ? const Color(0xFF2A3550).withValues(alpha: 0.80) : Colors.white.withValues(alpha: 0.90);
}

// ── Text styles ─────────────────────────────────────────────────────────────
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w800,
    color: AppColors.darkBase, height: 1.2,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.darkBase,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, color: AppColors.textMedium, fontWeight: FontWeight.w400,
  );
  static const TextStyle link = TextStyle(
    fontSize: 14, color: AppColors.cyan, fontWeight: FontWeight.w600,
  );
  static const TextStyle buttonText = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: Colors.white, letterSpacing: 0.3,
  );
}

// ── AppTheme ────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.scaffoldBg,
    colorScheme: const ColorScheme.light(primary: AppColors.primaryBlue),
    inputDecorationTheme: _inputTheme(AppColors.inputBg, AppColors.inputBorder),
  );

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF141B30),
    colorScheme: const ColorScheme.dark(primary: AppColors.cyan),
    inputDecorationTheme: _inputTheme(const Color(0xFF252D45), const Color(0xFF3A4560)),
  );

  static InputDecorationTheme _inputTheme(Color fill, Color border) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fill,
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.midTone, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      );

  // Keep old getter for any remaining references
  static ThemeData get theme => light;
}

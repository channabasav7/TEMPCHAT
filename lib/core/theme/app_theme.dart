import 'package:flutter/material.dart';

/// Dark palette – the primary app palette.
class AppColors {
  // Brand
  static const Color primaryOrange = Color(0xFFE25C2B);
  static const Color primaryOrangeLight = Color(0xFFFF7A45);

  // Dark Palette
  static const Color bg = Color(0xFF0D0F14);
  static const Color card = Color(0xFF161B22);
  static const Color cardLight = Color(0xFF1E2530);
  static const Color border = Color(0xFF2A3140);
  static const Color text = Color(0xFFECF0F1);
  static const Color muted = Color(0xFF8B96A7);
  static const Color dim = Color(0xFF4E5A6B);

  // Status Accents
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentRed = Color(0xFFEF4444);

  // Legacy aliases (kept for compile compatibility)
  @Deprecated('Use AppColors.bg')
  static const Color darkBg = bg;
  @Deprecated('Use AppColors.card')
  static const Color cardBg = card;
  @Deprecated('Use AppColors.cardLight')
  static const Color cardBgLight = cardLight;
  @Deprecated('Use AppColors.border')
  static const Color borderDark = border;
  @Deprecated('Use AppColors.muted')
  static const Color textMuted = muted;
  @Deprecated('Use AppColors.dim')
  static const Color textDim = dim;
  @Deprecated('Use AppColors.text')
  static const Color textWhite = text;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      primaryColor: AppColors.primaryOrange,
      fontFamily: null,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryOrange,
        surface: AppColors.card,
        onSurface: AppColors.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.text),
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      dividerColor: AppColors.border,
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.card,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.dim),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.dim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryOrange;
          return AppColors.border;
        }),
      ),
    );
  }

  // Keep old getter name as alias so existing references still compile
  static ThemeData get lightTheme => darkTheme;
}

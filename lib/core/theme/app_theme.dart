import 'package:flutter/material.dart';

/// Dark palette – the primary app palette.
class AppColors {
  // Brand
  static const Color primaryOrange = Color(0xFFE25C2B);
  static const Color primaryOrangeLight = Color(0xFFFF7A45);

  // Dark Palette
  static const Color darkBg = Color(0xFF0D0F14);
  static const Color darkCard = Color(0xFF161B22);
  static const Color darkCardLight = Color(0xFF1E2530);
  static const Color darkBorder = Color(0xFF2A3140);
  static const Color darkText = Color(0xFFECF0F1);
  static const Color darkMuted = Color(0xFF8B96A7);
  static const Color darkDim = Color(0xFF4E5A6B);

  // Legacy names used by screens that rely on the default dark palette.
  static const Color bg = darkBg;
  static const Color card = darkCard;
  static const Color cardLight = darkCardLight;
  static const Color border = darkBorder;
  static const Color text = darkText;
  static const Color muted = darkMuted;
  static const Color dim = darkDim;

  // Light Palette
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardLight = Color(0xFFF1F3F5);
  static const Color lightBorder = Color(0xFFDEE2E6);
  static const Color lightText = Color(0xFF212529);
  static const Color lightMuted = Color(0xFF6C757D);
  static const Color lightDim = Color(0xFFADB5BD);

  // Status Accents (shared)
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentRed = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      primaryColor: AppColors.primaryOrange,
      fontFamily: null,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryOrange,
        surface: AppColors.darkCard,
        onSurface: AppColors.darkText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.darkText),
        titleTextStyle: TextStyle(
          color: AppColors.darkText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      dividerColor: AppColors.darkBorder,
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.darkCard,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.darkDim),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.darkDim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryOrange;
          return AppColors.darkBorder;
        }),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkBg,
        selectedItemColor: AppColors.primaryOrange,
        unselectedItemColor: AppColors.darkMuted,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      primaryColor: AppColors.primaryOrange,
      fontFamily: null,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryOrange,
        surface: AppColors.lightCard,
        onSurface: AppColors.lightText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.lightText),
        titleTextStyle: TextStyle(
          color: AppColors.lightText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      dividerColor: AppColors.lightBorder,
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.lightCard,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.lightDim),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.lightDim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryOrange;
          return AppColors.lightBorder;
        }),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.lightCard,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightBg,
        selectedItemColor: AppColors.primaryOrange,
        unselectedItemColor: AppColors.lightMuted,
      ),
    );
  }
}
import 'package:flutter/material.dart';

/// Central design tokens for the whole app.
/// Kept deliberately simple & high-contrast for patients with memory
/// impairment: big text, big touch targets, calm colors, minimal clutter.
class AppColors {
  static const Color background = Color(0xFFF6F8FA);
  static const Color surface = Color(0xFFFFFFFF);

  // Calm primary palette (used mostly on Patient side)
  static const Color primary = Color(0xFF3E7C97); // calm teal-blue
  static const Color primaryDark = Color(0xFF2C5A70);
  static const Color primaryLight = Color(0xFFDCEBF1);

  // Warm accent (used for primary CTAs on Patient side)
  static const Color accent = Color(0xFFF2994A);
  static const Color accentLight = Color(0xFFFDEBD9);

  // Caregiver side gets a distinct but harmonious secondary color
  static const Color caregiver = Color(0xFF6C63A6);
  static const Color caregiverLight = Color(0xFFEAE8F5);

  static const Color success = Color(0xFF3FA76A);
  static const Color successLight = Color(0xFFDFF3E7);
  static const Color warning = Color(0xFFE0A93E);
  static const Color danger = Color(0xFFD9605A);
  static const Color dangerLight = Color(0xFFFAE1E0);

  static const Color textPrimary = Color(0xFF223142);
  static const Color textSecondary = Color(0xFF5B6B7A);
  static const Color divider = Color(0xFFE3E9ED);
}

class AppRadius {
  static const double card = 20;
  static const double button = 18;
  static const double chip = 30;
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          )
          .copyWith(
            headlineLarge: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            headlineMedium: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            titleLarge: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            titleMedium: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            bodyLarge: const TextStyle(
              fontSize: 18,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
            bodyMedium: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(64),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

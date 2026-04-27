import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color palette mirrors src/index.css (Deep Ocean Teal + Royal Gold).
class AppColors {
  // Primary — vivid teal.
  static const primary = Color(0xFF1EA594);
  static const primaryGlow = Color(0xFF2DD4BF);
  static const primaryDeep = Color(0xFF12806F);

  // Accent — royal gold.
  static const accent = Color(0xFFF7B733);
  static const accentDeep = Color(0xFFB77A00);

  // Light surfaces.
  static const background = Color(0xFFF6FBFA);
  static const surface = Colors.white;
  static const card = Colors.white;
  static const muted = Color(0xFFEEF5F3);
  static const mutedForeground = Color(0xFF667C87);
  static const foreground = Color(0xFF0E2024);
  static const border = Color(0xFFDCE8E5);
  static const destructive = Color(0xFFE94545);

  // Dark surfaces.
  static const backgroundDark = Color(0xFF0B1518);
  static const surfaceDark = Color(0xFF111E22);
  static const cardDark = Color(0xFF172428);
  static const mutedDark = Color(0xFF1B2C31);
  static const mutedForegroundDark = Color(0xFF9AB0B7);
  static const foregroundDark = Color(0xFFEAF6F4);
  static const borderDark = Color(0xFF24363B);

  static const gradientPrimary = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF1FC0AE), Color(0xFF0F8B78)],
  );

  static const gradientAccent = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFFFFC94A), Color(0xFFE69400)],
  );

  static const gradientHero = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF0FAF7), Color(0xFFE4F4F0)],
  );

  static const gradientHeroDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0E1B1F), Color(0xFF0B1518)],
  );
}

ThemeData _buildLightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final textTheme = GoogleFonts.tajawalTextTheme(base.textTheme).apply(
    bodyColor: AppColors.foreground,
    displayColor: AppColors.foreground,
  );
  return base.copyWith(
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.black,
      surface: AppColors.surface,
      onSurface: AppColors.foreground,
      error: AppColors.destructive,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    dividerColor: AppColors.border,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.foreground,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.muted.withOpacity(0.55),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle:
          textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    ),
  );
}

ThemeData _buildDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final textTheme = GoogleFonts.tajawalTextTheme(base.textTheme).apply(
    bodyColor: AppColors.foregroundDark,
    displayColor: AppColors.foregroundDark,
  );
  return base.copyWith(
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryGlow,
      onPrimary: Colors.black,
      secondary: AppColors.accent,
      onSecondary: Colors.black,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.foregroundDark,
      error: AppColors.destructive,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    canvasColor: AppColors.backgroundDark,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    dividerColor: AppColors.borderDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.foregroundDark,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.mutedDark,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle:
          textTheme.bodyMedium?.copyWith(color: AppColors.mutedForegroundDark),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryGlow, width: 1.6),
      ),
    ),
  );
}

final ThemeData appLightTheme = _buildLightTheme();
final ThemeData appDarkTheme = _buildDarkTheme();

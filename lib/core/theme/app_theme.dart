import 'package:flutter/material.dart';

/// Design tokens and Material 3 theme configuration for NEXU VoiceDesk.
/// Crafted for high contrast, clean hierarchy, and glove-friendly touch targets.
class AppTheme {
  static const primarySlate = Color(0xFF0F172A);
  static const primaryDark = Color(0xFF1E293B);
  static const accentBlue = Color(0xFF2563EB);
  static const surfaceWhite = Colors.white;
  static const backgroundMuted = Color(0xFFF8FAFC);
  static const borderSubtle = Color(0xFFE2E8F0);
  static const borderMedium = Color(0xFFCBD5E1);

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF64748B);
  static const textSubtle = Color(0xFF94A3B8);
  static const textTertiary = Color(0xFF94A3B8);

  static const successEmerald = Color(0xFF10B981);
  static const successBg = Color(0xFFDCFCE7);
  static const successText = Color(0xFF15803D);

  static const warningAmber = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFEF3C7);
  static const warningText = Color(0xFFB45309);

  static const dangerRose = Color(0xFFEF4444);
  static const dangerBg = Color(0xFFFEE2E2);
  static const dangerText = Color(0xFFB91C1C);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentBlue,
        primary: primarySlate,
        secondary: accentBlue,
        surface: surfaceWhite,
      ),
      scaffoldBackgroundColor: backgroundMuted,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderSubtle, width: 0.8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 0.8,
        space: 1,
      ),
    );
  }
}

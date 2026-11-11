import 'package:flutter/material.dart';

class AppTheme {
  // Industrial High-Contrast Color Palette
  static const primaryNavy = Color(0xFF0F172A);
  static const accentBlue = Color(0xFF2563EB);
  static const accentBlueLight = Color(0xFF3B82F6);
  static const surfaceDark = Color(0xFF1E293B);
  static const cardBackground = Color(0xFFF8FAFC);
  static const backgroundLight = Color(0xFFF1F5F9);
  
  // Status & Priority Colors
  static const highPriorityRed = Color(0xFFDC2626);
  static const mediumPriorityAmber = Color(0xFFD97706);
  static const lowPriorityGreen = Color(0xFF16A34A);
  static const infoTeal = Color(0xFF0D9488);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentBlue,
        primary: accentBlue,
        secondary: accentBlueLight,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}

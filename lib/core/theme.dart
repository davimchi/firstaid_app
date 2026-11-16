import 'package:flutter/material.dart';

class AppTheme {
  // Colors from the mockup
  static const Color background = Color(0xFFFAF9F6);
  static const Color surface = Colors.white;
  static const Color primaryRed = Color(0xFFC84B31); // Emergency Red
  static const Color softRedBg = Color(0xFFF9E8E6);
  static const Color sageGreen = Color(0xFFDDE5D8);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMuted = Color(0xFF6B6B6B);
  static const Color border = Color(0xFFE8E8E8);

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter', // Flutter fallback is fine
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        surface: surface,
        background: background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

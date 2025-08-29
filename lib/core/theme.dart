import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- COLOR PALETTE ---
  static const Color primaryColor = Color(0xFF3A4D89);
  static const Color secondaryColor = Color(0xFFEE8224);
  static const Color tertiaryColor = Color(0xFFA5D4F7);
  static const Color backgroundColor = Color(0xFFF0F8FF);
  static const Color textColor = Color(0xFF333333);

  // --- THEME GETTER ---
  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: textColor,
        onSurface: textColor,
      ),
    );

    // --- TYPOGRAPHY ---
    // This is the key change. It tells Flutter to try 'HemiHead' first,
    // and if a character is missing, use 'Russo One' as the backup.
    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(
        fontFamily: 'HemiHead',
        fontFamilyFallback: [GoogleFonts.russoOne().fontFamily!],
        bodyColor: textColor,
        displayColor: textColor,
      ),
    );
  }
}

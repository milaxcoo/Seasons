import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- COLOR PALETTE ---
  static const Color primaryColor = Color(0xFF3A4D89);
  static const Color secondaryColor = Color(0xFFEE8224);
  static const Color tertiaryColor = Color(0xFFA5D4F7);
  static const Color backgroundColor = Color(0xFFF0F8FF);
  static const Color textColor = Color(0xFF333333);
  
  // --- RUDN BRAND COLORS ---
  static const Color rudnGreenColor = Color(0xFF23a74c);
  static const Color rudnRedColor = Color(0xFFD32F2F); // Standard red for alerts/errors

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
        surface: backgroundColor, // Background became surface
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor, // onBackground became onSurface
      ),
    );

    // --- TYPOGRAPHY ---

    // Use 'Gentium Book Plus' as the body font to match seasons.rudn.ru website
    // This font supports both Latin and Cyrillic characters
    final baseTextTheme = GoogleFonts.gentiumBookPlusTextTheme(baseTheme.textTheme)
        .copyWith(
          bodyLarge: GoogleFonts.gentiumBookPlus(
            textStyle: baseTheme.textTheme.bodyLarge,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: GoogleFonts.gentiumBookPlus(
            textStyle: baseTheme.textTheme.bodyMedium,
            fontWeight: FontWeight.w700,
          ),
          bodySmall: GoogleFonts.gentiumBookPlus(
            textStyle: baseTheme.textTheme.bodySmall,
            fontWeight: FontWeight.w700,
          ),
          labelLarge: GoogleFonts.gentiumBookPlus(
            textStyle: baseTheme.textTheme.labelLarge,
            fontWeight: FontWeight.w700,
          ),
          labelMedium: GoogleFonts.gentiumBookPlus(
            textStyle: baseTheme.textTheme.labelMedium,
            fontWeight: FontWeight.w700,
          ),
          labelSmall: GoogleFonts.gentiumBookPlus(
            textStyle: baseTheme.textTheme.labelSmall,
            fontWeight: FontWeight.w700,
          ),
        )
        .apply(
      bodyColor: textColor,
      displayColor: textColor,
    );

    // 2. --- ИСПРАВЛЕНИЕ ---
    // Теперь переопределяем ЗАГОЛОВКИ,
    // чтобы они использовали 'HemiHead'
    final finalTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontFamily: 'HemiHead',
        fontStyle: FontStyle.italic,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontFamily: 'HemiHead',
        fontStyle: FontStyle.italic,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontFamily: 'HemiHead',
        fontStyle: FontStyle.italic,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontFamily: 'HemiHead',
        fontStyle: FontStyle.italic,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontFamily: 'HemiHead',
        fontStyle: FontStyle.italic,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontFamily: 'HemiHead',
        fontStyle: FontStyle.italic,
      ),
      // 'titleLarge' часто используется для AppBar
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontFamily: 'HemiHead',
        fontStyle: FontStyle.italic,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontFamily: 'HemiHead',
        fontStyle: FontStyle.italic,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontFamily: 'HemiHead',
        fontStyle: FontStyle.italic,
      ),
      // Все остальные стили (body, label, button)
      // автоматически будут 'Exo 2' (Normal) из baseTextTheme.
    );

    // 3. --- ИСПРАВЛЕНИЕ ---
    // Применяем нашу новую, разделенную тему (finalTheme)
    // вместо старого 'apply'.
    return baseTheme.copyWith(
      textTheme: finalTheme,
    );
  }
}
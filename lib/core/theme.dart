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
        surface: backgroundColor, // Background became surface
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor, // onBackground became onSurface
      ),
    );

    // --- TYPOGRAPHY ---

    // 1. --- ИСПРАВЛЕНИЕ ---
    // Используем 'Exo 2' как ОСНОВНОЙ шрифт для ВСЕГО.
    // Он поддерживает и латиницу, и кириллицу, и НЕ курсивный.
    // Нам больше не нужен 'Russo One' или 'fontFamilyFallback'.
    final baseTextTheme = GoogleFonts.exo2TextTheme(baseTheme.textTheme)
        .copyWith(
          // --- ИЗМЕНЕНИЕ: Делаем Exo 2 жирнее (w700), чтобы он был похож на Russo One ---
          bodyLarge: GoogleFonts.exo2(
            textStyle: baseTheme.textTheme.bodyLarge,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: GoogleFonts.exo2(
            textStyle: baseTheme.textTheme.bodyMedium,
            fontWeight: FontWeight.w700,
          ),
          bodySmall: GoogleFonts.exo2(
            textStyle: baseTheme.textTheme.bodySmall,
            fontWeight: FontWeight.w700,
          ),
          labelLarge: GoogleFonts.exo2(
            textStyle: baseTheme.textTheme.labelLarge,
            fontWeight: FontWeight.w700,
          ),
          labelMedium: GoogleFonts.exo2(
            textStyle: baseTheme.textTheme.labelMedium,
            fontWeight: FontWeight.w700,
          ),
          labelSmall: GoogleFonts.exo2(
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
    // и принудительно ставим курсив.
    // 'Exo 2' (из baseTextTheme) автоматически станет запасным шрифтом
    // для кириллицы в заголовках и тоже будет курсивным.
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
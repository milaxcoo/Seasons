import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- COLOR PALETTE (from your CSS) ---
  static const Color primaryColor = Color(0xFF3A4D89);
  static const Color secondaryColor = Color(0xFFEE8224);
  static const Color tertiaryColor = Color(0xFFA5D4F7);
  static const Color backgroundColor = Color(0xFFF9F9F9);
  static const Color textColor = Color(0xFF333333);

  // --- THEME GETTER ---
  static ThemeData get lightTheme {
    // Define the base text style with the shadow you requested.
    const TextStyle shadowTextStyle = TextStyle(
      shadows: [
        Shadow(
          color: Color.fromRGBO(66, 68, 90, 1),
          offset: Offset(3.0, 3.0),
          blurRadius: 6.0,
        ),
      ],
    );

    // Start with a base theme to build upon.
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

      // --- COMPONENT STYLING ---
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: shadowTextStyle.copyWith(
          fontSize: 22,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: const Color.fromRGBO(255, 255, 255, 0.5),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: tertiaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
    );

    // --- TYPOGRAPHY ---
    return baseTheme.copyWith(
      textTheme: GoogleFonts.russoOneTextTheme(baseTheme.textTheme).apply(
        bodyColor: textColor,
        displayColor: textColor,
      ).copyWith(
        headlineLarge: baseTheme.textTheme.headlineLarge?.merge(shadowTextStyle),
        headlineMedium: baseTheme.textTheme.headlineMedium?.merge(shadowTextStyle),
        headlineSmall: baseTheme.textTheme.headlineSmall?.merge(shadowTextStyle),
        titleLarge: baseTheme.textTheme.titleLarge?.merge(shadowTextStyle),
        titleMedium: baseTheme.textTheme.titleMedium?.merge(shadowTextStyle),
        titleSmall: baseTheme.textTheme.titleSmall?.merge(shadowTextStyle),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package.google_fonts/google_fonts.dart';

// This class holds the centralized theme data for the entire application.
// It ensures a consistent visual identity (colors, fonts, component styles)
// across all screens.
class AppTheme {
  // --- COLOR PALETTE ---
  // Defines the primary colors used in the app, as per the requirements.
  static const Color primaryColor = Color(0xFFE2725B); // Terracotta
  static const Color accentColor = Color(0xFFF5F5DC);  // Beige
  static const Color backgroundColor = Color(0xFFFFFAF0); // Off-white
  static const Color textColor = Color(0xFF333333); // Dark grey for text
  static const Color whiteColor = Colors.white;

  // --- THEME GETTER ---
  // A static getter that returns the fully configured ThemeData object.
  // This is the single source of truth for the app's theme.
  static ThemeData get lightTheme {
    // Start with a base theme to build upon.
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      // The color scheme is the foundation of the theme.
      // It's generated from a seed color for consistency.
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        background: backgroundColor,
        surface: whiteColor, // Cards and dialogs will use this color
        onPrimary: whiteColor, // Text/icons on primary color
        onSecondary: textColor,
        onBackground: textColor,
        onSurface: textColor,
      ),
      scaffoldBackgroundColor: backgroundColor,

      // --- COMPONENT STYLING ---
      // Pre-defined styles for common widgets.

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: whiteColor, // Title and icon color
        elevation: 2,
        centerTitle: true,
      ),

      // Card Theme
      cardTheme: CardThemeData( 
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: whiteColor,
      ),

      // ElevatedButton Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: whiteColor,
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

      // TextField (InputDecoration) Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: whiteColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
        ),
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
      ),

      // TabBar Theme
      tabBarTheme: const TabBarThemeData( // Corrected from TabBarTheme to TabBarThemeData
        labelColor: whiteColor,
        unselectedLabelColor: whiteColor,
        indicatorColor: accentColor,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );

    // --- TYPOGRAPHY ---
    // Apply the 'Montserrat' font to the base theme's text styles.
    // This ensures all text in the app uses the specified font family by default.
    return baseTheme.copyWith(
      textTheme: GoogleFonts.montserratTextTheme(baseTheme.textTheme).apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
    );
  }
}

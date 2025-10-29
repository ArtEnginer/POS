import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors - Optimized for speed and clarity
  static const Color primaryColor = Color(0xFF2196F3); // Blue - Fast action
  static const Color secondaryColor = Color(0xFF4CAF50); // Green - Success
  static const Color errorColor = Color(0xFFF44336); // Red - Alert
  static const Color warningColor = Color(0xFFFF9800); // Orange - Warning
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);

  // Cashier specific colors
  static const Color addItemColor = Color(0xFF4CAF50);
  static const Color removeItemColor = Color(0xFFF44336);
  static const Color paymentColor = Color(0xFF2196F3);
  static const Color discountColor = Color(0xFFFF9800);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),
      textTheme: GoogleFonts.robotoTextTheme().copyWith(
        // Large text for easy reading on cashier screen
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displayMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        headlineLarge: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        headlineMedium: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        bodyLarge: const TextStyle(fontSize: 16, color: textPrimaryColor),
        bodyMedium: const TextStyle(fontSize: 14, color: textPrimaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

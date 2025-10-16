import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Modern Blue
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryVariant = Color(0xFF1976D2);

  // Secondary Colors - Amber/Orange
  static const Color secondary = Color(0xFFFF6F00);
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFE65100);

  // Background
  static const Color background = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2C2C2C);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textDisabled = Color(0xFFE0E0E0);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);

  // Functional Colors
  static const Color accent = Color(0xFFFF6F00);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);

  // Transaction Colors
  static const Color sale = Color(0xFF4CAF50);
  static const Color refund = Color(0xFFE53935);
  static const Color pending = Color(0xFFFF9800);
  static const Color cancelled = Color(0xFF9E9E9E);

  // Payment Method Colors
  static const Color cash = Color(0xFF4CAF50);
  static const Color card = Color(0xFF2196F3);
  static const Color qris = Color(0xFF9C27B0);
  static const Color transfer = Color(0xFFFF9800);
  static const Color ewallet = Color(0xFF00BCD4);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF1E88E5),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE53935),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFFEB3B),
    Color(0xFF795548),
  ];

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Sync Status Colors
  static const Color synced = Color(0xFF4CAF50);
  static const Color syncPending = Color(0xFFFF9800);
  static const Color syncFailed = Color(0xFFE53935);
  static const Color syncConflict = Color(0xFF9C27B0);

  // Shimmer Colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}

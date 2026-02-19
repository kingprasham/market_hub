import 'package:flutter/material.dart';

class ColorConstants {
  // Primary Colors - Orange/Blue theme as requested
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color primaryColor = Color(0xFFFF6B35); // Main accent - Orange
  static const Color secondaryColor = Color(0xFF1E88E5); // Secondary - Blue

  // Light shades
  static const Color primaryLight = Color(0xFFFF8A5C);
  static const Color primaryDark = Color(0xFFE55A2B);
  static const Color secondaryLight = Color(0xFF42A5F5);
  static const Color secondaryDark = Color(0xFF1565C0);

  // Background Colors - Light/White theme as requested
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textLight = Color(0xFFADB5BD);

  // Market Colors
  static const Color positiveGreen = Color(0xFF00C853);
  static const Color negativeRed = Color(0xFFFF1744);
  static const Color positiveGreenLight = Color(0xFFE8F5E9);
  static const Color negativeRedLight = Color(0xFFFFEBEE);

  // UI Element Colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color dividerColor = Color(0xFFEEEEEE);
  static const Color inputBackground = Color(0xFFF5F5F5);
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color shadowColor = Color(0x1A000000);

  // Bottom Nav & App Bar
  static const Color navBarBackground = Color(0xFFFFFFFF);
  static const Color navBarActive = Color(0xFFFF6B35);
  static const Color navBarInactive = Color(0xFF9E9E9E);

  // Status Colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryOrange, Color(0xFFFF8A5C)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, Color(0xFF42A5F5)],
  );
}

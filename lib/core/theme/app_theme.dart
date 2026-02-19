import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/color_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: ColorConstants.primaryColor,
      scaffoldBackgroundColor: ColorConstants.backgroundColor,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: ColorConstants.primaryOrange,
        secondary: ColorConstants.primaryBlue,
        surface: ColorConstants.surfaceColor,
        error: ColorConstants.errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: ColorConstants.textPrimary,
        onError: Colors.white,
      ),

      // Text Theme
      textTheme: GoogleFonts.poppinsTextTheme(),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: ColorConstants.surfaceColor,
        foregroundColor: ColorConstants.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(
          color: ColorConstants.textPrimary,
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ColorConstants.textPrimary,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ColorConstants.navBarBackground,
        selectedItemColor: ColorConstants.navBarActive,
        unselectedItemColor: ColorConstants.navBarInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: ColorConstants.cardColor,
        elevation: 2,
        shadowColor: ColorConstants.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorConstants.primaryColor,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.primaryColor,
          side: const BorderSide(color: ColorConstants.primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorConstants.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.errorColor, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: ColorConstants.textHint,
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: ColorConstants.textSecondary,
        ),
        errorStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: ColorConstants.errorColor,
        ),
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: ColorConstants.primaryColor,
        unselectedLabelColor: ColorConstants.textSecondary,
        indicatorColor: ColorConstants.primaryColor,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: ColorConstants.dividerColor,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: ColorConstants.textPrimary,
        size: 24,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColorConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: ColorConstants.inputBackground,
        selectedColor: ColorConstants.primaryColor.withOpacity(0.2),
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: ColorConstants.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ColorConstants.textPrimary,
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: ColorConstants.surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ColorConstants.textPrimary,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: ColorConstants.textSecondary,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColorConstants.surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}

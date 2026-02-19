import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_constants.dart';

class TextStyles {
  // Headings
  static TextStyle h1 = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: ColorConstants.textPrimary,
    height: 1.2,
  );

  static TextStyle h2 = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: ColorConstants.textPrimary,
    height: 1.3,
  );

  static TextStyle h3 = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: ColorConstants.textPrimary,
    height: 1.3,
  );

  static TextStyle h4 = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: ColorConstants.textPrimary,
    height: 1.4,
  );

  static TextStyle h5 = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ColorConstants.textPrimary,
    height: 1.4,
  );

  static TextStyle h6 = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ColorConstants.textPrimary,
    height: 1.4,
  );

  // Caption
  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: ColorConstants.textSecondary,
    height: 1.4,
  );

  // Body Text
  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: ColorConstants.textPrimary,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: ColorConstants.textPrimary,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: ColorConstants.textSecondary,
    height: 1.5,
  );

  // Labels
  static TextStyle labelLarge = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ColorConstants.textPrimary,
    height: 1.4,
  );

  static TextStyle labelMedium = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: ColorConstants.textSecondary,
    height: 1.4,
  );

  static TextStyle labelSmall = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: ColorConstants.textHint,
    height: 1.4,
  );

  // Price Text
  static TextStyle priceText = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: ColorConstants.textPrimary,
  );

  static TextStyle priceLarge = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: ColorConstants.textPrimary,
  );

  // Change Text
  static TextStyle changePositive = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: ColorConstants.positiveGreen,
  );

  static TextStyle changeNegative = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: ColorConstants.negativeRed,
  );

  // Button Text
  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle buttonTextSecondary = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ColorConstants.primaryColor,
  );

  // Link Text
  static TextStyle linkText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ColorConstants.primaryBlue,
    decoration: TextDecoration.underline,
  );

  // Hint Text
  static TextStyle hintText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: ColorConstants.textHint,
  );

  // AppBar Title
  static TextStyle appBarTitle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: ColorConstants.textPrimary,
  );

  // Tab Text
  static TextStyle tabActive = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ColorConstants.primaryColor,
  );

  static TextStyle tabInactive = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: ColorConstants.textSecondary,
  );
}

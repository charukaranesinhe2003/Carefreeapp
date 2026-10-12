import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Same palette as the Cycle Care screens (dashboard, calendar, learn).
class AppColors {
  static const blush = Color(0xFFFDF2F8);
  static const blushDeep = Color(0xFFFFE4E6);
  static const primary = Color(0xFFE97495);
  static const primaryDark = Color(0xFFB01848);
  static const plum = Color(0xFF4C1D95);
  static const ink = Color(0xFF4C1D95);
  static const muted = Color(0xFF9CA3AF);
  static const line = Color(0xFFFFE4E6);
  static const card = Color(0xFFFFE4E6);
  static const teal = Color(0xFFE97495);
  static const tealDeep = Color(0xFF4A0F2B);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE97495), Color(0xFFB01848)],
  );

  static const cardShadow = [
    BoxShadow(
      color: Color(0x16E97495),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];
}

ThemeData buildTheme() {
  final textTheme = GoogleFonts.outfitTextTheme().copyWith(
    displayLarge: GoogleFonts.outfit(
      color: AppColors.ink,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      height: 1.05,
    ),
    titleLarge: GoogleFonts.outfit(
      color: AppColors.ink,
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: GoogleFonts.outfit(color: AppColors.ink, fontSize: 16),
    bodyMedium: GoogleFonts.outfit(color: AppColors.ink, fontSize: 14),
  ).apply(fontFamilyFallback: [GoogleFonts.notoSansSinhala().fontFamily!]);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.blush,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.primary,
      surface: AppColors.card,
    ),
    textTheme: textTheme,
    splashFactory: InkRipple.splashFactory,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.plum,
      contentTextStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: GoogleFonts.outfit(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    ),
  );
}

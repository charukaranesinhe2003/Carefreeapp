import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFE97495); // Deep pinkish
  static const Color backgroundColor = Color(0xFFFDF2F8); // Very light pastel pink
  static const Color cardColor = Color(0xFFFFE4E6); // Light pink card
  static const Color textDark = Color(0xFF4C1D95); // Deep maroon/purple text
  static const Color textLight = Color(0xFF9CA3AF);

  // Added for the Private Education subsystem (Member 3).
  static const Color primaryDark = Color(0xFFB01848); // Pressed state, title accents
  static const Color maroon = Color(0xFF4A0F2B); // Dark cards, HIDE button, quiz background
  static const Color success = Color(0xFF2E9E6B); // "Saved Offline", offline banner
  static const Color surface = Colors.white; // Cards and sheets

  /// Outfit has no Sinhala glyphs, so Sinhala text falls back to the bundled
  /// Noto Sans Sinhala (see assets/google_fonts).
  static List<String> get sinhalaFallback =>
      [GoogleFonts.notoSansSinhala().fontFamily!];

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
        background: backgroundColor,
        surface: cardColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
            color: textDark, fontSize: 32, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(
            color: textDark, fontSize: 24, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.outfit(color: textDark, fontSize: 16),
        bodyMedium: GoogleFonts.outfit(color: textDark, fontSize: 14),
      ).apply(fontFamilyFallback: sinhalaFallback),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

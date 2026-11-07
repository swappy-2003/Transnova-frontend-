import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Figma E-Wallet Coral Palette
  static const Color primary = Color(0xFFFF4B4B); // Vibrant Fintech Coral Red
  static const Color primaryDark = Color(0xFFE03838);
  static const Color primaryLight = Color(0xFFFFF0F0); // Tint for badges and icon buttons
  static const Color accent = Color(0xFF00B894); // Emerald Green for Inflow / Success
  static const Color accentLight = Color(0xFFE6FAF5);
  static const Color warning = Color(0xFFFF9F43); // Amber for Pending / Promo
  static const Color warningLight = Color(0xFFFFF4E8);
  static const Color info = Color(0xFF0984E3); // Sky Blue for Receive / Info
  static const Color infoLight = Color(0xFFEBF5FF);
  static const Color purple = Color(0xFF6C5CE7);
  static const Color purpleLight = Color(0xFFF1F0FD);
  static const Color error = Color(0xFFFF3838);

  // Modern Light Background & Card Surfaces
  static const Color background = Color(0xFFF6F7FB); // Ultra clean app background
  static const Color surface = Color(0xFFFFFFFF); // Pure white cards
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E232C); // Charcoal Black
  static const Color textSecondary = Color(0xFF7D848F); // Refined Slate Grey
  static const Color textMuted = Color(0xFFA2A8B5);
  static const Color border = Color(0xFFEFF1F5);
  static const Color divider = Color(0xFFF1F3F7);

  // Soft Fintech Card Shadow
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF1A1D26).withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get primaryShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F9FC),
        hintStyle: GoogleFonts.plusJakartaSans(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
          shadowColor: primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  // Backward compatibility alias
  static ThemeData get darkTheme => lightTheme;
}

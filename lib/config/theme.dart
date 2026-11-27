import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// IntPay-inspired Global Fintech Design System for Transnova
///
/// Palette:
/// - Obsidian Black (#101310) for anchor surfaces, dark cards, and navigation pills
/// - Pure White (#FFFFFF) for scannable content canvases
/// - Vibrant Green (#12B76A) for primary financial actions & hero balance cards
/// - Deep Green (#006D3C) when white text or high-contrast green text is needed
/// - Reward Yellow (#FFD84D) for rewards, promo pills, and attention dots
class AppTheme {
  // Core Brand Colors
  static const Color brandBlack = Color(0xFF101310);
  static const Color brandWhite = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF12B76A); // IntPay Vibrant Green
  static const Color primaryDark = Color(0xFF006D3C); // Deep Green
  static const Color primaryLight = Color(0xFFC2FFD1); // Soft Green container
  static const Color onPrimaryLight = Color(0xFF00210E);

  // Semantic & Accent Colors
  static const Color accent = Color(0xFF00894D); // Success / Inflow Green
  static const Color accentLight = Color(0xFFC2FFD1);
  static const Color rewardYellow = Color(0xFFFFD84D); // Strategic Yellow
  static const Color rewardYellowSoft = Color(0xFFFFF0C8);
  static const Color onRewardYellowSoft = Color(0xFF231B00);

  static const Color warning = Color(0xFFE6A100);
  static const Color warningLight = Color(0xFFFFF0C8);
  static const Color info = Color(0xFF006D3C);
  static const Color infoLight = Color(0xFFE6F5E6);
  static const Color purple = Color(0xFF101310);
  static const Color purpleLight = Color(0xFFF0F1EC);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorLight = Color(0xFFFFEDEA);

  // Neutral-Green Tinted Surfaces
  static const Color background = Color(0xFFFFFFFF); // Pure white canvas
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF6F8F6); // Soft-tinted card surface
  static const Color surfaceContainer = Color(0xFFF0F1EC);
  static const Color surfaceHigh = Color(0xFFE6F5E6);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFF6F8F6);

  // Text & Outline Colors
  static const Color textPrimary = Color(0xFF101310); // Deep Obsidian
  static const Color textSecondary = Color(0xFF454844); // On-surface variant
  static const Color textMuted = Color(0xFF757873); // Outline / muted
  static const Color darkSurfaceVariantText = Color(0xFFC5C7C2);
  static const Color border = Color(0xFFE1E3DE); // Outline-variant hairline
  static const Color divider = Color(0xFFE1E3DE);
  static const Color darkBorder = Color(0xFF2E312E);

  // Subtle ambient shadow for floating pills & hero surfaces
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: brandBlack.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get primaryShadow => [
        BoxShadow(
          color: brandBlack.withValues(alpha: 0.14),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // Typography helpers matching Mulish (display/headline), Instrument Sans (UI/body), Source Code Pro (mono)
  static TextStyle displayStyle({
    double fontSize = 32,
    FontWeight fontWeight = FontWeight.w800,
    Color color = textPrimary,
    double letterSpacing = -0.5,
  }) =>
      GoogleFonts.mulish(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle uiStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = textPrimary,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.instrumentSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle monoStyle({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w500,
    Color color = textPrimary,
  }) =>
      GoogleFonts.sourceCodePro(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: rewardYellow,
        surface: surface,
        error: error,
        onPrimary: brandBlack,
        onSecondary: brandBlack,
        onSurface: textPrimary,
      ),
      fontFamily: GoogleFonts.instrumentSans().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.instrumentSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.1,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLow,
        hintStyle: GoogleFonts.instrumentSans(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: brandBlack, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: brandBlack,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.instrumentSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // Backward compatibility alias
  static ThemeData get darkTheme => lightTheme;
}

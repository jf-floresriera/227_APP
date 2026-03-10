import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Purdue University official brand palette
/// Source: Purdue Brand Guidelines
abstract final class PurdueColors {
  // Primary
  static const boilermakerGold = Color(0xFFCFB991);
  static const black = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);

  // Secondary
  static const rushGold = Color(0xFFDAA900);
  static const agedGold = Color(0xFF8E6F3E);
  static const steel = Color(0xFF555960);
  static const railwayGray = Color(0xFF6F727B);
  static const dust = Color(0xFFC4BFC0);
  static const sandstone = Color(0xFFDAD0C6);

  // Semantic (disease risk levels)
  static const riskLow = Color(0xFF4CAF50);
  static const riskMedium = Color(0xFFFF9800);
  static const riskHigh = Color(0xFFF44336);
  static const riskVeryHigh = Color(0xFF7B1FA2);
}

ThemeData buildPurdueTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: PurdueColors.boilermakerGold,
    primary: PurdueColors.boilermakerGold,
    onPrimary: PurdueColors.black,
    secondary: PurdueColors.agedGold,
    onSecondary: PurdueColors.white,
    surface: PurdueColors.white,
    onSurface: PurdueColors.black,
    error: PurdueColors.riskHigh,
    brightness: Brightness.light,
  );

  final textTheme = GoogleFonts.interTextTheme().copyWith(
    displayLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: PurdueColors.black,
      letterSpacing: -0.5,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: PurdueColors.black,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: PurdueColors.black,
    ),
    bodyLarge: GoogleFonts.inter(fontSize: 16, color: PurdueColors.black),
    bodyMedium: GoogleFonts.inter(fontSize: 14, color: PurdueColors.steel),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: PurdueColors.black,
      foregroundColor: PurdueColors.boilermakerGold,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: PurdueColors.boilermakerGold),
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: PurdueColors.black,
      indicatorColor: PurdueColors.boilermakerGold.withOpacity(0.2),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: PurdueColors.boilermakerGold);
        }
        return const IconThemeData(color: PurdueColors.railwayGray);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return textTheme.labelSmall?.copyWith(color: PurdueColors.boilermakerGold);
        }
        return textTheme.labelSmall?.copyWith(color: PurdueColors.railwayGray);
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PurdueColors.boilermakerGold,
        foregroundColor: PurdueColors.black,
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: PurdueColors.black,
        foregroundColor: PurdueColors.boilermakerGold,
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: PurdueColors.white,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: PurdueColors.boilermakerGold, width: 2),
      ),
      labelStyle: textTheme.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: PurdueColors.sandstone,
      selectedColor: PurdueColors.boilermakerGold,
      labelStyle: textTheme.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(color: PurdueColors.dust, thickness: 1),
    scaffoldBackgroundColor: const Color(0xFFF5F3F0),
  );
}

/// Widget helpers para colores de riesgo
Color riskColor(String? level) {
  return switch (level) {
    'low' => PurdueColors.riskLow,
    'medium' => PurdueColors.riskMedium,
    'high' => PurdueColors.riskHigh,
    'very_high' => PurdueColors.riskVeryHigh,
    _ => PurdueColors.dust,
  };
}

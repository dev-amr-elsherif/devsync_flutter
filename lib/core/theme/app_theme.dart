import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Color Palette ──────────────────────────────────────────────
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9B93FF);
  static const Color secondary = Color(0xFF00E5FF);
  static const Color secondaryDark = Color(0xFF00B8D4);
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceLight = Color(0xFF1E2640);
  static const Color cardBg = Color(0xFF161D2F);
  static const Color textPrimary = Color(0xFFF8FAFF);
  static const Color textSecondary = Color(0xFF8892B0);
  static const Color textMuted = Color(0xFF4A5568);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF5370);
  static const Color divider = Color(0xFF1E2D40);

  // ─── Gradients ──────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF0D1526), Color(0xFF0A1628)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A2240), Color(0xFF111827)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Glass Morphism Decoration ───────────────────────────────────
  static BoxDecoration glassMorphismDecoration({
    double blur = 20,
    Color? borderColor,
    double borderWidth = 1.0,
    double borderRadius = 20,
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.12),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.08),
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration glowDecoration({
    Color glowColor = primary,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.3),
          blurRadius: 25,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: glowColor.withValues(alpha: 0.15),
          blurRadius: 50,
          spreadRadius: -5,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // ─── Text Styles ────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.5,
        height: 1.1,
      );

  static TextStyle get displayMedium => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.3,
        height: 1.2,
      );

  static TextStyle get headlineLarge => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle get headlineMedium => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.1,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get codeMono => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
      );

  // ─── ThemeData ──────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: textPrimary,
        onSecondary: background,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        titleLarge: titleLarge,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: headlineMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: bodyMedium.copyWith(color: textMuted),
        labelStyle: bodyMedium,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      iconTheme: const IconThemeData(color: textSecondary),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceLight,
        contentTextStyle: bodyMedium.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

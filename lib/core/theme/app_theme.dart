import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ─── Shared / Brand Colors ──────────────────────────────────────
  static const Color primary       = Color(0xFF6C63FF);
  static const Color primaryLight  = Color(0xFF9B93FF);
  static const Color secondary     = Color(0xFF00E5FF);
  static const Color secondaryDark = Color(0xFF00B8D4);
  static const Color success       = Color(0xFF00E676);
  static const Color warning       = Color(0xFFFFB300);
  static const Color error         = Color(0xFFFF5370);

  // ─── Dark Palette ───────────────────────────────────────────────
  static const Color _darkBackground    = Color(0xFF0A0E1A);
  static const Color _darkSurface       = Color(0xFF111827);
  static const Color _darkSurfaceLight  = Color(0xFF1E2640);
  static const Color _darkCardBg        = Color(0xFF161D2F);
  static const Color _darkTextPrimary   = Color(0xFFF8FAFF);
  static const Color _darkTextSecondary = Color(0xFF8892B0);
  static const Color _darkTextMuted     = Color(0xFF4A5568);
  static const Color _darkDivider       = Color(0xFF1E2D40);

  // ─── Light Palette ──────────────────────────────────────────────
  static const Color _lightBackground    = Color(0xFFF4F6FF);
  static const Color _lightSurface       = Color(0xFFFFFFFF);
  static const Color _lightSurfaceLight  = Color(0xFFE8EEFF);
  static const Color _lightCardBg        = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary   = Color(0xFF0D0F1A);
  static const Color _lightTextSecondary = Color(0xFF4A5568);
  static const Color _lightTextMuted     = Color(0xFF9BA3B8);
  static const Color _lightDivider       = Color(0xFFDDE1F0);

  // ================================================================
  // ⚠️  Backward-compat static getters (dark values)
  // الـ widgets القديمة بتستخدمهم — متمسحش
  // ================================================================
  static Color get background   => _darkBackground;
  static Color get surface      => _darkSurface;
  static Color get surfaceLight => _darkSurfaceLight;
  static Color get cardBg       => _darkCardBg;
  static Color get textPrimary  => _darkTextPrimary;
  static Color get textSecondary=> _darkTextSecondary;
  static Color get textMuted    => _darkTextMuted;
  static Color get divider      => _darkDivider;

  // Text style getters (backward compat)
  static TextStyle get displayLarge  => _displayLarge(_darkTextPrimary);
  static TextStyle get displayMedium => _displayMedium(_darkTextPrimary);
  static TextStyle get headlineLarge => _headlineLarge(_darkTextPrimary);
  static TextStyle get headlineMedium=> _headlineMedium(_darkTextPrimary);
  static TextStyle get titleLarge    => _titleLarge(_darkTextPrimary);
  static TextStyle get bodyLarge     => _bodyLarge(_darkTextSecondary);
  static TextStyle get bodyMedium    => _bodyMedium(_darkTextSecondary);
  static TextStyle get bodySmall     => _bodySmall(_darkTextSecondary);
  static TextStyle get labelLarge    => _labelLarge(_darkTextPrimary);
  static TextStyle get codeMono      => _codeMono(secondary);

  // ─── Gradients ──────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ⚠️ backward compat — بتحل مشكلة const constructor
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF0D1526), Color(0xFF0A1628)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundGradientDark = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF0D1526), Color(0xFF0A1628)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundGradientLight = LinearGradient(
    colors: [Color(0xFFF4F6FF), Color(0xFFEEF1FF), Color(0xFFE8EEFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A2240), Color(0xFF111827)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // helper لاختيار الـ gradient حسب الـ theme (للاستخدام الجديد غير const)
  static LinearGradient backgroundGradientOf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? backgroundGradientDark : backgroundGradientLight;
  }

  // ─── Glass Morphism ─────────────────────────────────────────────
  static BoxDecoration glassMorphismDecoration({
    bool isDark = true,
    double blur = 20,
    Color? borderColor,
    double borderWidth = 1.0,
    double borderRadius = 20,
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ??
          (isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.7)),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ??
            (isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08)),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: isDark ? 0.08 : 0.12),
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

  // ─── Public ThemeData ────────────────────────────────────────────
  static ThemeData get darkTheme  => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  // ─── Internal Builder ────────────────────────────────────────────
  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg          = isDark ? _darkBackground    : _lightBackground;
    final sf          = isDark ? _darkSurface       : _lightSurface;
    final sfLight     = isDark ? _darkSurfaceLight  : _lightSurfaceLight;
    final card        = isDark ? _darkCardBg        : _lightCardBg;
    final txtPrimary  = isDark ? _darkTextPrimary   : _lightTextPrimary;
    final txtSecondary= isDark ? _darkTextSecondary : _lightTextSecondary;
    final txtMuted    = isDark ? _darkTextMuted     : _lightTextMuted;
    final div         = isDark ? _darkDivider       : _lightDivider;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: isDark ? _darkBackground : _lightBackground,
        surface: sf,
        onSurface: txtPrimary,
        error: error,
        onError: Colors.white,
      ),
      extensions: [
        AppColors(
          background:    bg,
          surface:       sf,
          surfaceLight:  sfLight,
          cardBg:        card,
          textPrimary:   txtPrimary,
          textSecondary: txtSecondary,
          textMuted:     txtMuted,
          divider:       div,
          isDark:        isDark,
        ),
      ],
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).copyWith(
        displayLarge:  _displayLarge(txtPrimary),
        displayMedium: _displayMedium(txtPrimary),
        headlineLarge: _headlineLarge(txtPrimary),
        headlineMedium:_headlineMedium(txtPrimary),
        titleLarge:    _titleLarge(txtPrimary),
        bodyLarge:     _bodyLarge(txtSecondary),
        bodyMedium:    _bodyMedium(txtSecondary),
        bodySmall:     _bodySmall(txtSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: txtPrimary),
        titleTextStyle: _headlineMedium(txtPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sfLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: div, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: _bodyMedium(txtMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      dividerTheme: DividerThemeData(color: div, thickness: 1),
      cardTheme: CardThemeData(
        color: card,
        elevation: isDark ? 0 : 2,
        shadowColor: primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      iconTheme: IconThemeData(color: txtSecondary),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: sfLight,
        contentTextStyle: _bodyMedium(txtPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Text Style Helpers ──────────────────────────────────────────
  static TextStyle _displayLarge(Color c) => GoogleFonts.outfit(
      fontSize: 36, fontWeight: FontWeight.w800, color: c,
      letterSpacing: -0.5, height: 1.1);

  static TextStyle _displayMedium(Color c) => GoogleFonts.outfit(
      fontSize: 28, fontWeight: FontWeight.w700, color: c,
      letterSpacing: -0.3, height: 1.2);

  static TextStyle _headlineLarge(Color c) => GoogleFonts.outfit(
      fontSize: 22, fontWeight: FontWeight.w700, color: c,
      letterSpacing: -0.2);

  static TextStyle _headlineMedium(Color c) => GoogleFonts.outfit(
      fontSize: 18, fontWeight: FontWeight.w600, color: c);

  static TextStyle _titleLarge(Color c) => GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w600, color: c,
      letterSpacing: 0.1);

  static TextStyle _bodyLarge(Color c) => GoogleFonts.inter(
      fontSize: 15, fontWeight: FontWeight.w400, color: c, height: 1.6);

  static TextStyle _bodyMedium(Color c) => GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w400, color: c, height: 1.5);

  static TextStyle _bodySmall(Color c) => GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w400, color: c);

  static TextStyle _labelLarge(Color c) => GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w600, color: c,
      letterSpacing: 0.5);

  static TextStyle _codeMono(Color c) => GoogleFonts.jetBrainsMono(
      fontSize: 12, fontWeight: FontWeight.w400, color: c);
}
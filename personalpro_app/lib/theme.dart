import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta Dark / Neon Gym Theme
  static const Color bgDark = Color(0xFF121212);
  static const Color surfaceCard = Color(0xFF1C1F26);
  static const Color surfaceElevated = Color(0xFF252A34);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color performanceRed = Color(0xFFE53935);
  static const Color electricBlue = Color(0xFF00B0FF);
  static const Color warningAmber = Color(0xFFFFB300);
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFF9EA7B8);

  static const List<String> fallbackFonts = [
    'Plus Jakarta Sans',
    'Roboto',
    'Segoe UI',
    'Helvetica Neue',
    'Arial',
    'Segoe UI Emoji',
    'Apple Color Emoji',
    'Noto Color Emoji',
    'sans-serif',
  ];

  static TextStyle _withFallback(TextStyle? style) {
    final s = style ?? const TextStyle();
    return s.copyWith(
      fontFamilyFallback: fallbackFonts,
      color: s.color ?? textPrimary,
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final rawTextTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    final textTheme = rawTextTheme.copyWith(
      displayLarge: _withFallback(rawTextTheme.displayLarge),
      displayMedium: _withFallback(rawTextTheme.displayMedium),
      displaySmall: _withFallback(rawTextTheme.displaySmall),
      headlineLarge: _withFallback(rawTextTheme.headlineLarge),
      headlineMedium: _withFallback(rawTextTheme.headlineMedium),
      headlineSmall: _withFallback(rawTextTheme.headlineSmall),
      titleLarge: _withFallback(rawTextTheme.titleLarge),
      titleMedium: _withFallback(rawTextTheme.titleMedium),
      titleSmall: _withFallback(rawTextTheme.titleSmall),
      bodyLarge: _withFallback(rawTextTheme.bodyLarge),
      bodyMedium: _withFallback(rawTextTheme.bodyMedium),
      bodySmall: _withFallback(rawTextTheme.bodySmall),
      labelLarge: _withFallback(rawTextTheme.labelLarge),
      labelMedium: _withFallback(rawTextTheme.labelMedium),
      labelSmall: _withFallback(rawTextTheme.labelSmall),
    );

    return base.copyWith(
      scaffoldBackgroundColor: bgDark,
      primaryColor: neonGreen,
      colorScheme: const ColorScheme.dark(
        primary: neonGreen,
        secondary: performanceRed,
        tertiary: electricBlue,
        surface: surfaceCard,
        error: performanceRed,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF16181D),
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _withFallback(
          GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: _withFallback(
          GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceCard,
        titleTextStyle: _withFallback(
          GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        contentTextStyle: _withFallback(
          GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: textPrimary,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        labelStyle: _withFallback(const TextStyle(color: textSecondary)),
        hintStyle: _withFallback(const TextStyle(color: textSecondary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonGreen, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: _withFallback(
            GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

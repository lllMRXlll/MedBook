import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final class AppTheme {
  static const Color _primary = Color(0xFF167C74);
  static const Color _secondary = Color(0xFF87BFA9);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF4FAF8);

  static ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: _primary,
          secondary: _secondary,
          tertiary: const Color(0xFFDBF1E8),
          surface: _surface,
          surfaceContainerHighest: const Color(0xFFE3F0EC),
          onSurfaceVariant: const Color(0xFF5E6D68),
          outlineVariant: const Color(0xFFD7E4DF),
        );

    final baseTextTheme = GoogleFonts.manropeTextTheme().copyWith(
      displaySmall: GoogleFonts.manrope(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF13312D),
      ),
      headlineSmall: GoogleFonts.manrope(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF173630),
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: GoogleFonts.manrope(fontSize: 16, height: 1.45),
      bodyMedium: GoogleFonts.manrope(fontSize: 14, height: 1.45),
      labelLarge: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _background,
      textTheme: baseTextTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFD9E6E2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFD9E6E2)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        side: BorderSide.none,
        selectedColor: colorScheme.primaryContainer,
        backgroundColor: Colors.white,
        labelStyle: baseTextTheme.bodyMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: Color(0xFFBFD4CC)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        elevation: 0,
        indicatorColor: colorScheme.primaryContainer,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0EBE7),
        thickness: 1,
      ),
    );
  }
}

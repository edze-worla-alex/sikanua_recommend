import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SikanuaTheme {
  // Palette
  static const forest      = Color(0xFF1A6B3C);
  static const forestDark  = Color(0xFF134F2D);
  static const forestLight = Color(0xFFD6EFE0);
  static const sage        = Color(0xFF2E8B57);
  static const amber       = Color(0xFFF4A72A);
  static const amberLight  = Color(0xFFFEF3D7);
  static const ink         = Color(0xFF1C2B24);
  static const background  = Color(0xFFF7FAF8);
  static const surface     = Color(0xFFFFFFFF);
  static const border      = Color(0xFFD6EFE0);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: forest,
      primary:   forest,
      secondary: sage,
      tertiary:  amber,
      background: background,
      surface:   surface,
    ),
    scaffoldBackgroundColor: background,
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.sora(
        fontSize: 32, fontWeight: FontWeight.w700, color: ink,
      ),
      displayMedium: GoogleFonts.sora(
        fontSize: 24, fontWeight: FontWeight.w700, color: ink,
      ),
      titleLarge: GoogleFonts.sora(
        fontSize: 18, fontWeight: FontWeight.w600, color: ink,
      ),
      titleMedium: GoogleFonts.sora(
        fontSize: 15, fontWeight: FontWeight.w600, color: ink,
      ),
      bodyLarge:  GoogleFonts.inter(fontSize: 15, color: ink),
      bodyMedium: GoogleFonts.inter(fontSize: 13, color: ink),
      bodySmall:  GoogleFonts.inter(fontSize: 11, color: Color(0xFF6B8C7A)),
    ),
    cardTheme: CardTheme(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: forest,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: forest.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
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
        borderSide: const BorderSide(color: forest, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

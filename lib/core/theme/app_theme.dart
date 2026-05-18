import 'package:flutter/material.dart';

// Ei class ta GameHub platform er dynamic theme configurations logic setup kore.
// Eikhane standard theme colors, light mode, matte dark mode, 
// ar iconic electric cyberpunk neon modes load kora hoyeche.
class AppTheme {
  // Original Cyberpunk Color Palette (for compatibility & neon mode)
  // Neon elements like glowing purple, cyan blues, and hot electric pink parameters.
  static const Color neonPurple = Color(0xFFB523FA);
  static const Color cyanBlue = Color(0xFF00F3FF);
  static const Color electricPink = Color(0xFFFF00A0);
  static const Color darkBackground = Color(0xFF0D0E15);
  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Matte Dark Mode Palette (Medium eye relief theme)
  static const Color slateDark = Color(0xFF121420);
  static const Color slateGray = Color(0xFF1E2132);
  static const Color slateCyan = Color(0xFF0EA5E9);

  // Light Cyberpunk/Teal Palette (Daylight theme alternative)
  static const Color lightCanvas = Color(0xFFF1F5F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightAccent = Color(0xFF0284C7);

  // 1. Sleek Light Mode Theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightCanvas,
      primaryColor: lightAccent,
      colorScheme: const ColorScheme.light(
        primary: lightAccent,
        secondary: Color(0xFF0F172A),
        tertiary: Color(0xFF475569),
        surface: lightSurface,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Color(0xFF334155)),
        bodyMedium: TextStyle(color: Color(0xFF475569)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }

  // 2. Matte Slate Dark Mode Theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: slateDark,
      primaryColor: slateCyan,
      colorScheme: const ColorScheme.dark(
        primary: slateCyan,
        secondary: Color(0xFF94A3B8),
        tertiary: Color(0xFF64748B),
        surface: slateGray,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Color(0xFFCBD5E1)),
        bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: slateCyan,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }

  // 3. Electric Cyberpunk Neon Theme (Original Default Theme)
  // Eita holo GameHub platform er primary brand representation theme!
  static ThemeData get cyberpunkNeonTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: neonPurple,
      colorScheme: const ColorScheme.dark(
        primary: neonPurple,
        secondary: cyanBlue,
        tertiary: electricPink,
        surface: darkBackground,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Colors.white70),
        bodyMedium: TextStyle(color: Colors.white60),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }
}

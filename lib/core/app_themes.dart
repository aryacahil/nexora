import 'package:flutter/material.dart';

class AppThemes {
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8F7FF),
    primaryColor: const Color(0xFF7C3AED),
    fontFamily: 'Roboto',
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C3AED),
      brightness: Brightness.light,
    ),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFEDE9FE),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF8F7FF),
      elevation: 0,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
    ),
  );

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0A1A),
    primaryColor: const Color(0xFF9D5FFF),
    fontFamily: 'Roboto',
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF9D5FFF),
      brightness: Brightness.dark,
    ),
    cardColor: const Color(0xFF1A1225),
    dividerColor: const Color(0xFF2D1F4E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F0A1A),
      elevation: 0,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF1A1225),
    ),
  );
}
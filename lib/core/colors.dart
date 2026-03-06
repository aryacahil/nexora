import 'package:flutter/material.dart';
import 'theme_provider.dart';

class AppColors {
  static const Color primary = Color(0xFF7C3AED);
  static const Color accent = Color(0xFF8B5CF6);

  static Color get bg =>
      ThemeProvider.instance.isDarkMode
          ? const Color(0xFF0F0A1A)
          : const Color(0xFFF8F7FF);

  static Color get card =>
      ThemeProvider.instance.isDarkMode
          ? const Color(0xFF1A1225)
          : Colors.white;

  static Color get border =>
      ThemeProvider.instance.isDarkMode
          ? const Color(0xFF2D1F4E)
          : const Color(0xFFEDE9FE);

  static Color get textMain =>
      ThemeProvider.instance.isDarkMode
          ? Colors.white
          : const Color(0xFF1E1B4B);

  static Color get textDim =>
      ThemeProvider.instance.isDarkMode
          ? const Color(0xFF9CA3AF)
          : const Color(0xFF6B7280);
}
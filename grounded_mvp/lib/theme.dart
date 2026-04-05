import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const lavender = Color(0xFFB794F4);
  static const lavenderDark = Color(0xFF9F7AEA);
  static const charcoal = Color(0xFF121212);
  static const charcoalLight = Color(0xFF1E1E1E);
  static const chalk = Color(0xFFF7FAFC);
  static const slate500 = Color(0xFF64748B);
  static const slate400 = Color(0xFF94A3B8);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);
}

class AppTheme {
  static final _base = GoogleFonts.interTextTheme();

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7FAFC),
        textTheme: _base,
        colorScheme: const ColorScheme.light(
          primary: AppColors.lavender,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: AppColors.charcoal,
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.charcoal,
        textTheme: _base.apply(
          bodyColor: AppColors.chalk,
          displayColor: AppColors.chalk,
        ),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.lavender,
          onPrimary: Colors.white,
          surface: AppColors.charcoalLight,
          onSurface: AppColors.chalk,
        ),
      );
}

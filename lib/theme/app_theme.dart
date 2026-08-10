import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF4A3B32);
  static const Color textMuted = Color(0xFF8E8E8E);
  static const Color primaryOrange = Color(0xFFF09B42);
  static const Color accentOrange = Color(0xFFE87A5D);
  static const Color inputBackground = Color(0xFFF5EFE6);
  static const Color cardBackground = Color(0xFFFAF5EF);
  static const Color femaleBg = Color(0xFFFDE8E8);
  static const Color maleBg = Color(0xFFFFF3E0);
  static const Color iconDark = Color(0xFF4A3B32);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      fontFamily: 'CustomFont',
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryOrange,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryOrange,
        primary: AppColors.primaryOrange,
        secondary: AppColors.accentOrange,
        surface: AppColors.background,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textDark, fontFamily: 'CustomFont'),
        bodyMedium: TextStyle(color: AppColors.textDark, fontFamily: 'CustomFont'),
        titleLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontFamily: 'CustomFont'),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textDark),
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'CustomFont',
        ),
      ),
    );
  }
}

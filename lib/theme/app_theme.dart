import 'package:flutter/material.dart';

/// 웹 콘솔과 맞춘 teal / navy 토큰.
abstract final class AppColors {
  static const navy = Color(0xFF2A3F54);
  static const heading = Color(0xFF2A3F54);
  static const body = Color(0xFF73879C);
  static const muted = Color(0xFF9AA7B5);
  static const bg = Color(0xFFF7F7F7);
  static const card = Colors.white;
  static const border = Color(0xFFE6E9ED);
  static const primary = Color(0xFF1ABB9C);
  static const primaryDark = Color(0xFF169F85);
  static const primarySoft = Color(0xFFE8F8F5);
  static const success = Color(0xFF26B99A);
  static const successSoft = Color(0xFFE8F8F5);
  static const warning = Color(0xFFF0AD4E);
  static const warningSoft = Color(0xFFFCF8E3);
  static const danger = Color(0xFFD9534F);
  static const dangerSoft = Color(0xFFF2DEDE);
  static const info = Color(0xFF5BC0DE);
  static const infoSoft = Color(0xFFD9EDF7);
  static const purple = Color(0xFF9B59B6);
  static const purpleSoft = Color(0xFFF4ECF7);
}

ThemeData buildAppTheme() {
  const seed = AppColors.primary;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    primary: AppColors.primary,
    surface: AppColors.card,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme.copyWith(primary: AppColors.primary),
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        side: const BorderSide(color: AppColors.border, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy,
      contentTextStyle: const TextStyle(fontSize: 15, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dividerColor: AppColors.border,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.heading,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.heading,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.heading,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.heading),
      bodyMedium: TextStyle(fontSize: 15, color: AppColors.body),
    ),
  );
}

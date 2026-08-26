import 'package:flutter/material.dart';

/// 스크린샷(근무 탭)에서 추출한 재사용 토큰.
abstract final class AppColors {
  // Brand (caregiver app purple)
  static const primary = Color(0xFF6B50C3);
  static const primaryDark = Color(0xFF5A41B0);
  static const primarySoft = Color(0xFFF1EDFC);
  static const primaryMid = Color(0xFF7262BC);

  // Surfaces
  static const bg = Color(0xFFF7F8FC);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE8E9EE);

  // Text
  static const heading = Color(0xFF15181D);
  static const body = Color(0xFF84868A);
  static const muted = Color(0xFFA4A7AC);
  static const navInactive = Color(0xFFB9BABC);

  // Legacy / status (기존 뱃지·로그인 등에서 사용)
  static const navy = Color(0xFF2A3F54);
  static const success = Color(0xFF26B99A);
  static const successSoft = Color(0xFFE8F8F5);
  static const warning = Color(0xFFF0AD4E);
  static const warningSoft = Color(0xFFFCF8E3);
  static const danger = Color(0xFFD9534F);
  static const dangerSoft = Color(0xFFF2DEDE);
  static const info = Color(0xFF5BC0DE);
  static const infoSoft = Color(0xFFD9EDF7);
  static const purple = primary;
  static const purpleSoft = primarySoft;
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  static const pageH = 20.0;
  static const pageTop = 8.0;
  static const section = 16.0;
}

abstract final class AppRadii {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const pill = 12.0;
  static const sheet = 20.0;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get pillAll => BorderRadius.circular(pill);
}

abstract final class AppType {
  static const pageTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: AppColors.heading,
    letterSpacing: -0.4,
  );

  static const sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.heading,
  );

  static const emptyTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: AppColors.heading,
  );

  static const emptySubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.body,
  );

  static const tabSelected = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.primary,
  );

  static const tabUnselected = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.muted,
  );

  static const navLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.card,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme.copyWith(primary: AppColors.primary),
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.card,
      foregroundColor: AppColors.heading,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.heading,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.mdAll,
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.heading,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        side: const BorderSide(color: AppColors.border, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: AppRadii.mdAll,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.mdAll,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.mdAll,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.heading,
      contentTextStyle: const TextStyle(fontSize: 15, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dividerColor: AppColors.border,
    textTheme: const TextTheme(
      headlineSmall: AppType.pageTitle,
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

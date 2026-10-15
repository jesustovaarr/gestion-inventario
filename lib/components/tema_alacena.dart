import 'package:flutter/material.dart';

abstract final class PantryColors {
  static const background = Color(0xFFF3FAF4);
  static const surface = Color(0xFFFFFFFF);
  static const green = Color(0xFF006B49);
  static const greenLight = Color(0xFFDDEFE3);
  static const ink = Color(0xFF1F3028);
  static const muted = Color(0xFF7A897F);
  static const border = Color(0xFFE7F0E9);
  static const red = Color(0xFFC94747);
  static const redLight = Color(0xFFFCE4E0);
  static const orange = Color(0xFFCE841F);
  static const orangeLight = Color(0xFFFFF0D9);
  static const amber = Color(0xFFD2A525);
  static const amberLight = Color(0xFFFFF6D6);
}

abstract final class PantryTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PantryColors.green,
      primary: PantryColors.green,
      surface: PantryColors.surface,
      onSurface: PantryColors.ink,
    ),
    scaffoldBackgroundColor: PantryColors.background,
    dividerColor: PantryColors.border,
    appBarTheme: const AppBarTheme(
      backgroundColor: PantryColors.background,
      foregroundColor: PantryColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: PantryColors.green,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
        color: PantryColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: PantryColors.ink,
      ),
      bodyMedium: TextStyle(fontSize: 13, color: PantryColors.ink),
      bodySmall: TextStyle(fontSize: 11, color: PantryColors.muted),
    ),
  );
}

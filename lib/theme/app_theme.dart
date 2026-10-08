import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF101412);
  static const surface = Color(0xFF1B211E);
  static const border = Color(0xFF303A33);
  static const green = Color(0xFFB6F36A);
  static const orange = Color(0xFFFFC16E);
  static const text = Color(0xFFF3F5EF);
  static const muted = Color(0xFF98A69D);
}

ThemeData buildAppTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.green,
    onPrimary: AppColors.background,
    surface: AppColors.surface,
    onSurface: AppColors.text,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    surfaceTintColor: Colors.transparent,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(58),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.text,
      minimumSize: const Size(0, 48),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
);

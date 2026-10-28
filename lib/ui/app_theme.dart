import 'package:flutter/material.dart';

abstract final class AppPalette {
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF151515);
  static const elevatedSurface = Color(0xFF1C1C1C);
  static const separator = Color(0xFF303030);
  static const accent = Color(0xFFFF5A4F);
  static const accentMuted = Color(0xFF672A24);
  static const white = Color(0xFFF7F7F7);
  static const secondary = Color(0xFF9A9A9A);
}

ThemeData appTheme() {
  const colorScheme = ColorScheme.dark(
    primary: AppPalette.accent,
    onPrimary: AppPalette.white,
    surface: AppPalette.surface,
    onSurface: AppPalette.white,
    error: Color(0xFFFF6B6B),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppPalette.background,
    dividerColor: AppPalette.separator,
    fontFamily: 'sans-serif',
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.7),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, color: AppPalette.white),
      bodyMedium: TextStyle(fontSize: 14, color: AppPalette.secondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.elevatedSurface,
      hintStyle: const TextStyle(color: AppPalette.secondary),
      labelStyle: const TextStyle(color: AppPalette.secondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppPalette.separator),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppPalette.separator),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppPalette.accent, width: 1.5),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppPalette.surface,
      modalBackgroundColor: AppPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}

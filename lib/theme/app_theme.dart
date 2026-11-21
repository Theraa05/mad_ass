import 'package:flutter/material.dart';

/// TARUMT-inspired palette. Change the hex values here and the
/// whole app updates.
class TarumtColors {
  static const primary = Color(0xFF0B3C8C); // TARUMT blue
  static const primaryDark = Color(0xFF082B66);
  static const accent = Color(0xFFD62828); // TARUMT red
  static const ink = Color(0xFF111827);
  static const surface = Color(0xFFF4F6FA);
  static const border = Color(0xFFE1E5EE);
  static const muted = Color(0xFF6B7280);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFED8B00);

  // Soft tints used behind icons and chips
  static const primaryTint = Color(0xFFE7EEF9);
  static const accentTint = Color(0xFFFCE9E9);
  static const successTint = Color(0xFFE6F2E7);
  static const warningTint = Color(0xFFFFF1DC);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary],
  );
}

ThemeData buildAppTheme() {
  final outline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: TarumtColors.border),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TarumtColors.primary,
      primary: TarumtColors.primary,
      secondary: TarumtColors.accent,
    ),
    scaffoldBackgroundColor: TarumtColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: TarumtColors.surface,
      foregroundColor: TarumtColors.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: outline,
      enabledBorder: outline,
      focusedBorder: outline.copyWith(
        borderSide: const BorderSide(color: TarumtColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      isDense: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TarumtColors.primary,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TarumtColors.primary,
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        side: const BorderSide(color: TarumtColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

import 'package:flutter/material.dart';

abstract final class IthxPalette {
  static const canvas = Color(0xFFF3F4EE);
  static const canvasBorder = Color(0xFFD4DED7);
  static const forest = Color(0xFF0F352E);
  static const deepForest = Color(0xFF092420);
  static const forestBorder = Color(0xFF205047);
  static const cream = Color(0xFFF5EAD7);
  static const muted = Color(0xFF4F6B63);
  static const mutedOnDark = Color(0xFF93B2A8);
  static const danger = Color(0xFFBA1A1A);
  static const success = Color(0xFF147A5D);
}

ThemeData buildIthxTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: IthxPalette.forest,
        brightness: Brightness.light,
      ).copyWith(
        primary: IthxPalette.forest,
        onPrimary: IthxPalette.cream,
        secondary: IthxPalette.forestBorder,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: IthxPalette.forest,
        error: IthxPalette.danger,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: IthxPalette.canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: IthxPalette.canvas,
      foregroundColor: IthxPalette.forest,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: IthxPalette.canvasBorder),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: IthxPalette.forest,
        foregroundColor: IthxPalette.cream,
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

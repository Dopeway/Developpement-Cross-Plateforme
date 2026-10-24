import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const seed = Color(0xFF0B6B58);
  final colors = ColorScheme.fromSeed(
    seedColor: seed,
    surface: const Color(0xFFFFFCF7),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: const Color(0xFFFFFCF7),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

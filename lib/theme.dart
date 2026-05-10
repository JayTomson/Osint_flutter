import 'package:flutter/material.dart';
import 'models.dart';

ThemeData buildTheme(AppTheme t) {
  const seed = Color(0xFF6750A4);
  switch (t) {
    case AppTheme.light:
      return ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: seed, brightness: Brightness.light),
      );
    case AppTheme.dark:
      return ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: seed, brightness: Brightness.dark),
      );
    case AppTheme.amoled:
      final base = ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: seed, brightness: Brightness.dark),
      );
      return base.copyWith(
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        cardTheme: CardThemeData(
          color: const Color(0xFF0A0A0A),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF1F1F1F)),
          ),
        ),
        dialogTheme:
            const DialogThemeData(backgroundColor: Color(0xFF0A0A0A)),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF0A0A0A),
        ),
      );
  }
}

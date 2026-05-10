part of 'main.dart';

// ============================================================================
// THEME
// ============================================================================

ThemeData buildTheme(AppTheme t) {
  switch (t) {
    case AppTheme.light:
      return ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );
    case AppTheme.dark:
      return ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );
    case AppTheme.amoled:
      return ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ).copyWith(
          surface: Colors.black,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
        cardColor: const Color(0xFF111111),
        useMaterial3: true,
      );
  }
}

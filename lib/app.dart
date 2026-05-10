import 'package:flutter/material.dart';
import 'app_state.dart';
import 'theme.dart';
import 'screens/home_screen.dart';

class OsintApp extends StatelessWidget {
  const OsintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'OSINT V',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(AppState.instance.settings.theme),
          home: const HomeScreen(),
        );
      },
    );
  }
}

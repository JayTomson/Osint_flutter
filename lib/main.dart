import 'package:flutter/material.dart';
import 'app_state.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.init();
  runApp(const OsintApp());
}

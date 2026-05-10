// OSINT V — Cases-based OSINT data collection app
// Top-level entity is a "Case" (Дело). Each case contains its own targets
// (people / goals), connections graph, and evidence.
//
// Split into multiple files via Dart part/part-of.
// Drop the entire lib/ folder into your project.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

part 'l10n.dart';
part 'fuzzy_search.dart';
part 'models.dart';
part 'app_state.dart';
part 'value_detector.dart';
part 'theme.dart';
part 'widgets/dialogs.dart';
part 'screens/home_screen.dart';
part 'screens/case_screen.dart';
part 'screens/person_screen.dart';
part 'screens/settings_screen.dart';
part 'screens/marks_screen.dart';
part 'screens/graph_screen.dart';
part 'screens/global_map_screen.dart';
part 'tabs/info_tab.dart';
part 'tabs/connections_tab.dart';
part 'tabs/evidence_tab.dart';
part 'tabs/map_tab.dart';
part 'pdf/pdf_builder.dart';
part 'pdf/case_pdf_builder.dart';

// ============================================================================
// MAIN
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.init();
  runApp(const OsintApp());
}

// ============================================================================
// APP ROOT
// ============================================================================

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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';
import '../utils.dart';
import 'experimental_screen.dart';
import 'marks_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final settings = AppState.instance.settings;
        return Scaffold(
          appBar: AppBar(title: Text(tr('settings'))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            children: [
              // — Language —
              _SectionHeader(tr('language')),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DropdownButtonFormField<String>(
                    value: settings.language,
                    decoration:
                        InputDecoration(labelText: tr('language')),
                    items: const [
                      DropdownMenuItem(value: 'ru', child: Text('Русский')),
                      DropdownMenuItem(
                          value: 'en', child: Text('English')),
                    ],
                    onChanged: (v) async {
                      if (v == null) return;
                      settings.language = v;
                      await AppState.instance.persistSettingsOnly();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // — Theme —
              _SectionHeader(tr('theme')),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DropdownButtonFormField<AppTheme>(
                    value: settings.theme,
                    decoration:
                        InputDecoration(labelText: tr('theme')),
                    items: [
                      DropdownMenuItem(
                          value: AppTheme.light,
                          child: Text(tr('theme_light'))),
                      DropdownMenuItem(
                          value: AppTheme.dark,
                          child: Text(tr('theme_dark'))),
                      DropdownMenuItem(
                          value: AppTheme.amoled,
                          child: Text(tr('theme_amoled'))),
                    ],
                    onChanged: (v) async {
                      if (v == null) return;
                      settings.theme = v;
                      await AppState.instance.persistSettingsOnly();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // — Custom Marks —
              _SectionHeader(tr('custom_marks')),
              Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.bookmark_outline),
                  title: Text(tr('manage_marks')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MarksScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // — Experimental —
              _SectionHeader(tr('experimental_features')),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.science_outlined),
                  title: Text(tr('experimental_features')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const ExperimentalFeaturesScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // — Data —
              _SectionHeader(tr('data')),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.file_upload_outlined),
                      title: Text(tr('export_json')),
                      onTap: () => _exportJson(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.file_download_outlined),
                      title: Text(tr('import_json')),
                      onTap: () => _importJson(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.storage_outlined),
                      title: Text(tr('export_sqlite')),
                      onTap: () => _exportSqlite(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_outlined,
                          color: Colors.red),
                      title: Text(tr('reset_database'),
                          style: const TextStyle(color: Colors.red)),
                      onTap: () => _resetDatabase(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // — About —
              _SectionHeader(tr('about')),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('OSINT V',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(tr('about_description'),
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(tr('data_stored_locally'),
                          style: const TextStyle(fontSize: 12)),
                      Text(
                          '${tr("data_file")}: ${AppState.instance.dataFilePath}',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportJson(BuildContext context) async {
    try {
      final f = await AppState.instance.exportJsonFile();
      if (!context.mounted) return;
      await Share.shareXFiles([XFile(f.path)],
          subject: 'OSINT V export');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr("error")}: $e')),
      );
    }
  }

  Future<void> _importJson(BuildContext context) async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    try {
      await AppState.instance.importJsonFromFile(File(path));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('import_success'))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr("error")}: $e')),
      );
    }
  }

  Future<void> _exportSqlite(BuildContext context) async {
    try {
      final f = await AppState.instance.exportRawDb();
      if (!context.mounted) return;
      await Share.shareXFiles([XFile(f.path)],
          subject: 'OSINT V database');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr("error")}: $e')),
      );
    }
  }

  Future<void> _resetDatabase(BuildContext context) async {
    final ok = await showDeleteDialog(context);
    if (ok == true) {
      await AppState.instance.resetDatabase();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('database_reset'))),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 4),
        child: Text(title.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 1.1)),
      );
}

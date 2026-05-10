part of '../main.dart';

// ============================================================================
// SETTINGS SCREEN
// ============================================================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final s = AppState.instance.settings;
    return Scaffold(
      appBar: AppBar(title: Text(tr('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _section(tr('theme')),
          SegmentedButton<AppTheme>(
            segments: [
              ButtonSegment(value: AppTheme.light, label: Text(tr('light'))),
              ButtonSegment(value: AppTheme.dark, label: Text(tr('dark'))),
              ButtonSegment(value: AppTheme.amoled, label: Text(tr('amoled'))),
            ],
            selected: {s.theme},
            onSelectionChanged: (set) async {
              s.theme = set.first;
              await AppState.instance.persistSettingsOnly();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          _section(tr('language')),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'en', label: Text('EN')),
              ButtonSegment(value: 'ru', label: Text('RU')),
            ],
            selected: {s.language},
            onSelectionChanged: (set) async {
              s.language = set.first;
              await AppState.instance.persistSettingsOnly();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          _section(tr('storage_path')),
          Card(
            child: ListTile(
              title: Text(tr('storage_dir_info')),
              subtitle: Text(AppState.instance.dataFilePath),
              isThreeLine: true,
              leading: const Icon(Icons.folder_outlined),
            ),
          ),
          const SizedBox(height: 16),
          _section('JSON / DB'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: Text(tr('export_json')),
                  onTap: _exportJson,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(tr('import_json')),
                  onTap: _importJson,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: Text(tr('export_db')),
                  onTap: _exportRawDb,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(tr('reset_db'),
                      style: const TextStyle(color: Colors.red)),
                  onTap: _resetDb,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(tr('custom_marks')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.label_outline),
              title: Text(tr('custom_marks')),
              subtitle: Text(
                s.marks.isEmpty
                    ? tr('custom_marks_subtitle')
                    : '${s.marks.length} • ${tr('custom_marks_subtitle')}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MarksScreen()),
                );
                if (mounted) setState(() {});
              },
            ),
          ),
          const SizedBox(height: 16),
          _section(tr('experimental_features')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.science_outlined),
              title: Text(tr('experimental_features')),
              subtitle: Text(tr('experimental_subtitle')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ExperimentalFeaturesScreen()),
                );
                if (mounted) setState(() {});
              },
            ),
          ),
          const SizedBox(height: 16),
          _section(tr('tutorial')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(tr('tutorial_text'),
                  style: const TextStyle(height: 1.4)),
            ),
          ),
          const SizedBox(height: 16),
          _section(tr('about')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(tr('disclaimer')),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
        child: Text(title,
            style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w600)),
      );

  Future<void> _exportJson() async {
    final f = await AppState.instance.exportJsonFile();
    await Share.shareXFiles([XFile(f.path)], text: 'OSINT V data');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('snack_exported'))),
      );
    }
  }

  Future<void> _exportRawDb() async {
    final f = await AppState.instance.exportRawDb();
    await Share.shareXFiles([XFile(f.path)], text: 'OSINT V raw DB');
  }

  Future<void> _importJson() async {
    final res = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json']);
    if (res == null || res.files.single.path == null) return;
    await AppState.instance.importJsonFromFile(File(res.files.single.path!));
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('snack_imported'))),
      );
    }
  }

  Future<void> _resetDb() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('reset_db')),
        content: Text(tr('reset_confirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AppState.instance.resetDatabase();
      if (mounted) setState(() {});
    }
  }
}

// ============================================================================
// EXPERIMENTAL FEATURES SCREEN
// ============================================================================

class ExperimentalFeaturesScreen extends StatefulWidget {
  const ExperimentalFeaturesScreen({super.key});
  @override
  State<ExperimentalFeaturesScreen> createState() =>
      _ExperimentalFeaturesScreenState();
}

class _ExperimentalFeaturesScreenState
    extends State<ExperimentalFeaturesScreen> {
  ExperimentalFeatures get _exp =>
      AppState.instance.settings.experimental;

  Future<void> _save() async {
    await AppState.instance.persistSettingsOnly();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final exp = _exp;
    return Scaffold(
      appBar: AppBar(title: Text(tr('experimental_features'))),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Text(
              tr('experimental_subtitle'),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          _FeatureTile(
            icon: Icons.flag_outlined,
            title: tr('exp_priority'),
            subtitle: tr('exp_priority_desc'),
            value: exp.priority,
            onChanged: (v) {
              exp.priority = v;
              _save();
            },
          ),
          _FeatureTile(
            icon: Icons.map_outlined,
            title: tr('exp_global_map'),
            subtitle: tr('exp_global_map_desc'),
            value: exp.globalMap,
            onChanged: (v) {
              exp.globalMap = v;
              _save();
            },
          ),
          _FeatureTile(
            icon: Icons.image_outlined,
            title: tr('exp_export_graph_png'),
            subtitle: tr('exp_export_graph_png_desc'),
            value: exp.exportGraphPng,
            onChanged: (v) {
              exp.exportGraphPng = v;
              _save();
            },
          ),
          _FeatureTile(
            icon: Icons.label_outlined,
            title: tr('exp_case_tags'),
            subtitle: tr('exp_case_tags_desc'),
            value: exp.caseTags,
            onChanged: (v) {
              exp.caseTags = v;
              _save();
            },
          ),
          _FeatureTile(
            icon: Icons.map_outlined,
            title: tr('exp_export_map_png'),
            subtitle: tr('exp_export_map_png_desc'),
            value: exp.exportMapPng,
            onChanged: (v) {
              exp.exportMapPng = v;
              _save();
            },
          ),
          _FeatureTile(
            icon: Icons.picture_as_pdf_outlined,
            title: tr('exp_case_pdf'),
            subtitle: tr('exp_case_pdf_desc'),
            value: exp.casePdf,
            onChanged: (v) {
              exp.casePdf = v;
              _save();
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: SwitchListTile(
        secondary: Icon(
          icon,
          color: value ? theme.colorScheme.primary : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: value ? theme.colorScheme.primary : null,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

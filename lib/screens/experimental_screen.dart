import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';

class ExperimentalFeaturesScreen extends StatelessWidget {
  const ExperimentalFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final exp = AppState.instance.settings.experimental;
        return Scaffold(
          appBar: AppBar(title: Text(tr('experimental_features'))),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  tr('experimental_warning'),
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
              _FeatureTile(
                title: tr('feature_priority'),
                subtitle: tr('feature_priority_desc'),
                value: exp.priority,
                onChanged: (v) async {
                  exp.priority = v;
                  await AppState.instance.persistSettingsOnly();
                },
              ),
              _FeatureTile(
                title: tr('feature_global_map'),
                subtitle: tr('feature_global_map_desc'),
                value: exp.globalMap,
                onChanged: (v) async {
                  exp.globalMap = v;
                  await AppState.instance.persistSettingsOnly();
                },
              ),
              _FeatureTile(
                title: tr('feature_export_graph_png'),
                subtitle: tr('feature_export_graph_png_desc'),
                value: exp.exportGraphPng,
                onChanged: (v) async {
                  exp.exportGraphPng = v;
                  await AppState.instance.persistSettingsOnly();
                },
              ),
              _FeatureTile(
                title: tr('feature_case_tags'),
                subtitle: tr('feature_case_tags_desc'),
                value: exp.caseTags,
                onChanged: (v) async {
                  exp.caseTags = v;
                  await AppState.instance.persistSettingsOnly();
                },
              ),
              _FeatureTile(
                title: tr('feature_case_pdf'),
                subtitle: tr('feature_case_pdf_desc'),
                value: exp.casePdf,
                onChanged: (v) async {
                  exp.casePdf = v;
                  await AppState.instance.persistSettingsOnly();
                },
              ),
              _FeatureTile(
                title: tr('feature_export_map_png'),
                subtitle: tr('feature_export_map_png_desc'),
                value: exp.exportMapPng,
                onChanged: (v) async {
                  exp.exportMapPng = v;
                  await AppState.instance.persistSettingsOnly();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _FeatureTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

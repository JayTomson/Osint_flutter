import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';
import '../utils.dart';

class MarksScreen extends StatelessWidget {
  const MarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final marks = AppState.instance.settings.marks;
        return Scaffold(
          appBar: AppBar(title: Text(tr('custom_marks'))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  tr('marks_description'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              if (marks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    tr('no_marks'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              for (final mark in marks)
                _MarkTile(mark: mark),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addMark(context),
            icon: const Icon(Icons.add),
            label: Text(tr('add_mark')),
          ),
        );
      },
    );
  }

  Future<void> _addMark(BuildContext context) async {
    final charC = TextEditingController();
    final labelC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('add_mark')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: charC,
              autofocus: true,
              maxLength: 2,
              decoration: InputDecoration(
                labelText: tr('mark_char'),
                hintText: '★',
              ),
            ),
            TextField(
              controller: labelC,
              decoration: InputDecoration(
                labelText: tr('mark_label'),
                hintText: tr('mark_label_hint'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('add'))),
        ],
      ),
    );
    if (ok == true && charC.text.trim().isNotEmpty) {
      AppState.instance.settings.marks
          .add(CustomMark(char: charC.text.trim(), label: labelC.text.trim()));
      await AppState.instance.persistSettingsOnly();
    }
  }
}

class _MarkTile extends StatelessWidget {
  final CustomMark mark;
  const _MarkTile({required this.mark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(mark.char,
              style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold)),
        ),
        title: Text(mark.label.isEmpty ? mark.char : mark.label),
        subtitle: mark.label.isEmpty
            ? null
            : Text('${tr("mark_char")}: "${mark.char}"',
                style: const TextStyle(fontSize: 11)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            final ok = await showDeleteDialog(context);
            if (ok == true) {
              AppState.instance.settings.marks.remove(mark);
              await AppState.instance.persistSettingsOnly();
            }
          },
        ),
      ),
    );
  }
}

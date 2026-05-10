import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as pathLib;
import 'package:path_provider/path_provider.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';
import '../utils.dart';

class EvidenceTab extends StatelessWidget {
  final String caseId;
  final String personId;
  const EvidenceTab(
      {super.key, required this.caseId, required this.personId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final c = AppState.instance.findCase(caseId);
        final p = c?.findPerson(personId);
        if (c == null || p == null) return const SizedBox();
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          children: [
            if (p.evidence.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  tr('no_evidence'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            for (final ev in p.evidence)
              _EvidenceTile(
                  caseId: caseId, personId: personId, evidenceId: ev.id),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _addEvidence(context, p),
              icon: const Icon(Icons.add),
              label: Text(tr('add_evidence')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addEvidence(BuildContext context, Person p) async {
    final descC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('add_evidence')),
        content: TextField(
          controller: descC,
          autofocus: true,
          decoration:
              InputDecoration(labelText: tr('description_optional')),
          maxLines: 3,
          onSubmitted: (_) => Navigator.pop(ctx, true),
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
    if (ok == true) {
      p.evidence.add(EvidenceItem(description: descC.text.trim()));
      await AppState.instance.persist();
    }
  }
}

class _EvidenceTile extends StatelessWidget {
  final String caseId;
  final String personId;
  final String evidenceId;
  const _EvidenceTile(
      {required this.caseId,
      required this.personId,
      required this.evidenceId});

  @override
  Widget build(BuildContext context) {
    final c = AppState.instance.findCase(caseId);
    final p = c?.findPerson(personId);
    final ev = p?.evidence.where((e) => e.id == evidenceId).firstOrNull;
    if (c == null || p == null || ev == null) return const SizedBox();
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ev.description.isEmpty
                        ? tr('evidence_no_description')
                        : ev.description,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: tr('edit'),
                  onPressed: () => _editDescription(context, ev),
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file_outlined, size: 18),
                  tooltip: tr('attach_file'),
                  onPressed: () => _attachFile(context, ev),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  tooltip: tr('delete'),
                  onPressed: () async {
                    final ok = await showDeleteDialog(context);
                    if (ok == true) {
                      p.evidence.removeWhere((e) => e.id == ev.id);
                      await AppState.instance.persist();
                    }
                  },
                ),
              ],
            ),
            if (ev.filePaths.isNotEmpty) ...[
              const Divider(),
              for (final path in ev.filePaths)
                _FileTile(
                  path: path,
                  onDelete: () async {
                    ev.filePaths.remove(path);
                    await AppState.instance.persist();
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editDescription(
      BuildContext context, EvidenceItem ev) async {
    final c = TextEditingController(text: ev.description);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('edit')),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLines: 4,
          decoration:
              InputDecoration(labelText: tr('description')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('save'))),
        ],
      ),
    );
    if (ok == true) {
      ev.description = c.text.trim();
      await AppState.instance.persist();
    }
  }

  Future<void> _attachFile(BuildContext context, EvidenceItem ev) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;
    final docsDir = AppState.instance.docsDir;
    final evDir =
        Directory('${docsDir.path}/evidence/${ev.id}');
    await evDir.create(recursive: true);
    for (final pf in result.files) {
      final src = pf.path;
      if (src == null) continue;
      final dest =
          '${evDir.path}/${pathLib.basename(src)}';
      await File(src).copy(dest);
      if (!ev.filePaths.contains(dest)) ev.filePaths.add(dest);
    }
    await AppState.instance.persist();
  }
}

class _FileTile extends StatelessWidget {
  final String path;
  final VoidCallback onDelete;
  const _FileTile({required this.path, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final name = pathLib.basename(path);
    final isImage = isImagePath(path);
    final exists = File(path).existsSync();
    return ListTile(
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      leading: isImage && exists
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(File(path),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 28)),
            )
          : const Icon(Icons.insert_drive_file_outlined),
      title: Text(name,
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis),
      subtitle: exists ? null : Text(tr('file_missing'), style: const TextStyle(color: Colors.red, fontSize: 11)),
      onTap: exists ? () => OpenFile.open(path) : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
        onPressed: onDelete,
      ),
    );
  }
}

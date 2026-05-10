import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../detection.dart';
import '../l10n.dart';
import '../models.dart';
import '../utils.dart';
import 'map_screens.dart';

class InfoTab extends StatelessWidget {
  final String caseId;
  final String personId;
  const InfoTab({super.key, required this.caseId, required this.personId});

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
            for (final cat in p.categories) ...[
              _CategoryCard(
                  caseId: caseId,
                  personId: personId,
                  categoryId: cat.id),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _addCategory(context, p),
              icon: const Icon(Icons.add),
              label: Text(tr('add_category')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addCategory(BuildContext context, Person p) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('add_category')),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(labelText: tr('category_name')),
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
    if (ok == true && c.text.trim().isNotEmpty) {
      p.categories.add(CategoryBlock(name: c.text.trim()));
      await AppState.instance.persist();
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final String caseId;
  final String personId;
  final String categoryId;
  const _CategoryCard(
      {required this.caseId,
      required this.personId,
      required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final p =
        AppState.instance.findCase(caseId)?.findPerson(personId);
    final cat =
        p?.categories.where((c) => c.id == categoryId).firstOrNull;
    if (p == null || cat == null) return const SizedBox();
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    cat.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _renameCategory(context, p, cat),
                  tooltip: tr('rename'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  onPressed: () async {
                    final ok = await showDeleteDialog(context);
                    if (ok == true) {
                      p.categories.removeWhere((c) => c.id == cat.id);
                      await AppState.instance.persist();
                    }
                  },
                  tooltip: tr('delete'),
                ),
              ],
            ),
            const Divider(),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: (oldIdx, newIdx) async {
                if (newIdx > oldIdx) newIdx--;
                final item = cat.entries.removeAt(oldIdx);
                cat.entries.insert(newIdx, item);
                await AppState.instance.persist();
              },
              children: [
                for (var i = 0; i < cat.entries.length; i++)
                  _KvTile(
                    key: ValueKey(cat.entries[i].id),
                    caseId: caseId,
                    personId: personId,
                    categoryId: categoryId,
                    kvId: cat.entries[i].id,
                    index: i,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () => _addEntry(context, cat),
              icon: const Icon(Icons.add, size: 18),
              label: Text(tr('add_field')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameCategory(
      BuildContext context, Person p, CategoryBlock cat) async {
    final c = TextEditingController(text: cat.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('rename')),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(labelText: tr('category_name')),
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
    if (ok == true && c.text.trim().isNotEmpty) {
      cat.name = c.text.trim();
      await AppState.instance.persist();
    }
  }

  Future<void> _addEntry(BuildContext context, CategoryBlock cat) async {
    final keyC = TextEditingController();
    final valC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('add_field')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyC,
              autofocus: true,
              decoration: InputDecoration(labelText: tr('field_key')),
              onSubmitted: (_) => Navigator.pop(ctx, true),
            ),
            TextField(
              controller: valC,
              decoration: InputDecoration(labelText: tr('field_value')),
              onSubmitted: (_) => Navigator.pop(ctx, true),
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
    if (ok == true) {
      cat.entries.add(KeyValue(
        key: keyC.text.trim(),
        value: valC.text.trim(),
      ));
      await AppState.instance.persist();
    }
  }
}

class _KvTile extends StatelessWidget {
  final String caseId;
  final String personId;
  final String categoryId;
  final String kvId;
  final int index;
  const _KvTile({
    super.key,
    required this.caseId,
    required this.personId,
    required this.categoryId,
    required this.kvId,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final p =
        AppState.instance.findCase(caseId)?.findPerson(personId);
    final cat =
        p?.categories.where((c) => c.id == categoryId).firstOrNull;
    final kv = cat?.entries.where((e) => e.id == kvId).firstOrNull;
    if (p == null || cat == null || kv == null) return const SizedBox();
    return ListTile(
      key: ValueKey(kv.id),
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      leading: ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle, size: 18),
      ),
      title: kv.key.isEmpty ? null : Text(kv.key, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: kv.value.isNotEmpty
          ? _ValueText(
              caseId: caseId,
              personId: personId,
              value: kv.value,
            )
          : const Text('—', style: TextStyle(fontSize: 13)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            onPressed: () => _editKv(context, cat, kv),
            tooltip: tr('edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 16, color: Colors.red),
            onPressed: () async {
              cat.entries.removeWhere((e) => e.id == kv.id);
              await AppState.instance.persist();
            },
            tooltip: tr('delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _editKv(
      BuildContext context, CategoryBlock cat, KeyValue kv) async {
    final keyC = TextEditingController(text: kv.key);
    final valC = TextEditingController(text: kv.value);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('edit_field')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyC,
              autofocus: true,
              decoration: InputDecoration(labelText: tr('field_key')),
            ),
            TextField(
              controller: valC,
              decoration: InputDecoration(labelText: tr('field_value')),
              maxLines: 3,
            ),
          ],
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
      kv.key = keyC.text.trim();
      kv.value = valC.text.trim();
      await AppState.instance.persist();
    }
  }
}

class _ValueText extends StatelessWidget {
  final String caseId;
  final String personId;
  final String value;
  const _ValueText(
      {required this.caseId,
      required this.personId,
      required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coord = ValueDetector.extractCoord(value);
    final phone = ValueDetector.extractPhone(value);
    final card = ValueDetector.extractCard(value);
    final mark = ValueDetector.matchedCustomMark(value);

    final List<Widget> badges = [];

    if (coord != null) {
      badges.add(_badge(
        context,
        icon: Icons.map_outlined,
        label: tr('show_on_map'),
        color: theme.colorScheme.tertiary,
        onTap: () {
          final p =
              AppState.instance.findCase(caseId)?.findPerson(personId);
          if (p == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SingleMarkerMapScreen(
                  coord: coord, label: value),
            ),
          );
        },
      ));
    }

    if (phone != null) {
      badges.add(_badge(
        context,
        icon: Icons.phone_outlined,
        label: tr('call'),
        color: Colors.green,
        onTap: () async {
          final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'\s'), '')}');
          if (await canLaunchUrl(uri)) launchUrl(uri);
        },
      ));
    }

    if (card != null) {
      badges.add(_badge(
        context,
        icon: Icons.credit_card_outlined,
        label: tr('copy_card'),
        color: Colors.blue,
        onTap: () {
          Clipboard.setData(ClipboardData(text: card));
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(tr('copied'))));
        },
      ));
    }

    if (mark != null) {
      final marks = AppState.instance.settings.marks;
      final matchedMark = marks.where((m) => m.char == mark).firstOrNull;
      if (matchedMark != null && matchedMark.label.isNotEmpty) {
        badges.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(matchedMark.label,
              style:
                  TextStyle(fontSize: 11, color: theme.colorScheme.onPrimaryContainer)),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(tr('copied'))));
          },
          child: Text(value,
              style: const TextStyle(fontSize: 13),
              maxLines: 4,
              overflow: TextOverflow.ellipsis),
        ),
        if (badges.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 4, children: badges),
        ],
      ],
    );
  }

  Widget _badge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

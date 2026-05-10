import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';
import '../utils.dart';

class ConnectionsTab extends StatelessWidget {
  final String caseId;
  final String personId;
  const ConnectionsTab(
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
            if (p.connections.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  tr('no_connections'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            for (final link in p.connections)
              _ConnectionTile(
                caseId: caseId,
                personId: personId,
                linkId: link.id,
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _addConnection(context, c, p),
              icon: const Icon(Icons.add),
              label: Text(tr('add_connection')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addConnection(
      BuildContext context, CaseFile c, Person p) async {
    final others =
        c.people.where((other) => other.id != p.id).toList();
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('no_other_targets'))),
      );
      return;
    }
    Person? selected;
    final reasonC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: Text(tr('add_connection')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<Person>(
                isExpanded: true,
                hint: Text(tr('select_target')),
                value: selected,
                onChanged: (v) => setS(() => selected = v),
                items: others
                    .map((o) => DropdownMenuItem(
                          value: o,
                          child: Text(o.fullName),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonC,
                decoration:
                    InputDecoration(labelText: tr('reason_optional')),
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
        );
      }),
    );
    if (ok == true && selected != null) {
      final existingLink =
          p.connections.where((l) => l.targetPersonId == selected!.id).firstOrNull;
      if (existingLink != null) {
        if (reasonC.text.trim().isNotEmpty) {
          existingLink.reasons.add(reasonC.text.trim());
        }
      } else {
        p.connections.add(ConnectionLink(
          targetPersonId: selected!.id,
          reasons: reasonC.text.trim().isNotEmpty
              ? [reasonC.text.trim()]
              : [],
        ));
        final reverse = selected!.connections
            .where((l) => l.targetPersonId == p.id)
            .firstOrNull;
        if (reverse == null) {
          selected!.connections.add(ConnectionLink(
            targetPersonId: p.id,
            reasons: reasonC.text.trim().isNotEmpty
                ? [reasonC.text.trim()]
                : [],
          ));
        }
      }
      await AppState.instance.persist();
    }
  }
}

class _ConnectionTile extends StatelessWidget {
  final String caseId;
  final String personId;
  final String linkId;
  const _ConnectionTile(
      {required this.caseId,
      required this.personId,
      required this.linkId});

  @override
  Widget build(BuildContext context) {
    final c = AppState.instance.findCase(caseId);
    final p = c?.findPerson(personId);
    final link = p?.connections.where((l) => l.id == linkId).firstOrNull;
    if (c == null || p == null || link == null) return const SizedBox();
    final target = c.findPerson(link.targetPersonId);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    target?.initials ?? '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    target?.fullName ?? tr('unknown_target'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_comment_outlined, size: 18),
                  tooltip: tr('add_reason'),
                  onPressed: () => _addReason(context, link),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  tooltip: tr('delete'),
                  onPressed: () async {
                    final ok = await showDeleteDialog(context);
                    if (ok == true) {
                      p.connections
                          .removeWhere((l) => l.id == link.id);
                      target?.connections.removeWhere(
                          (l) => l.targetPersonId == p.id);
                      await AppState.instance.persist();
                    }
                  },
                ),
              ],
            ),
            if (link.reasons.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < link.reasons.length; i++)
                    GestureDetector(
                      onLongPress: () async {
                        final ok = await showDeleteDialog(context);
                        if (ok == true) {
                          link.reasons.removeAt(i);
                          await AppState.instance.persist();
                        }
                      },
                      child: Chip(
                        label: Text(link.reasons[i],
                            style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addReason(
      BuildContext context, ConnectionLink link) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('add_reason')),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(labelText: tr('reason')),
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
      link.reasons.add(c.text.trim());
      await AppState.instance.persist();
    }
  }
}

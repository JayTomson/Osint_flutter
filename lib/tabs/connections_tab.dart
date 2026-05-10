part of '../main.dart';

// ============================================================================
// CONNECTIONS TAB (within a single case)
// ============================================================================

class _ConnectionsTab extends StatefulWidget {
  final CaseFile caseFile;
  final Person person;
  final Future<void> Function() onChange;
  const _ConnectionsTab(
      {required this.caseFile,
      required this.person,
      required this.onChange});
  @override
  State<_ConnectionsTab> createState() => _ConnectionsTabState();
}

class _ConnectionsTabState extends State<_ConnectionsTab> {
  @override
  Widget build(BuildContext context) {
    final p = widget.person;
    return Stack(
      children: [
        if (p.connections.isEmpty)
          Center(
            child: Text(tr('no_connections_yet'),
                style: const TextStyle(color: Colors.grey)),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: p.connections.length,
            itemBuilder: (ctx, i) {
              final link = p.connections[i];
              final other = widget.caseFile.findPerson(link.targetPersonId);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(other?.initials ?? '?',
                        textAlign: TextAlign.center),
                  ),
                  title: Text(other?.fullName ?? '???'),
                  subtitle: link.reasons.isEmpty
                      ? Text(tr('reasons'))
                      : Text(link.reasons.join('\n')),
                  isThreeLine: link.reasons.length > 1,
                  onTap: () {
                    if (other != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PersonScreen(
                              caseId: widget.caseFile.id,
                              personId: other.id),
                        ),
                      );
                    }
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        await _editLink(link);
                      } else if (v == 'delete') {
                        final ok = await showDeleteDialog(context);
                        if (ok == true) {
                          setState(() => p.connections.removeAt(i));
                          await widget.onChange();
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text(tr('edit'))),
                      PopupMenuItem(value: 'delete', child: Text(tr('delete'))),
                    ],
                  ),
                ),
              );
            },
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'connFab',
            onPressed: _addConnection,
            icon: const Icon(Icons.link),
            label: Text(tr('add_connection')),
          ),
        ),
      ],
    );
  }

  Future<void> _addConnection() async {
    final all = widget.caseFile.people
        .where((p) => p.id != widget.person.id)
        .toList();
    if (all.isEmpty) return;
    final picked = await showDialog<Person>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr('select_person')),
        children: [
          for (final p in all)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, p),
              child: Text(p.fullName),
            ),
        ],
      ),
    );
    if (picked == null) return;
    final link = ConnectionLink(targetPersonId: picked.id);
    final ok = await _editLinkDialog(link, picked);
    if (ok) {
      setState(() => widget.person.connections.add(link));
      final alreadyLinked = picked.connections
          .any((c) => c.targetPersonId == widget.person.id);
      if (!alreadyLinked) {
        picked.connections.add(ConnectionLink(
          targetPersonId: widget.person.id,
          reasons: List.of(link.reasons),
        ));
      }
      await widget.onChange();
    }
  }

  Future<void> _editLink(ConnectionLink link) async {
    final other = widget.caseFile.findPerson(link.targetPersonId);
    if (other == null) return;
    final ok = await _editLinkDialog(link, other);
    if (ok) {
      setState(() {});
      await widget.onChange();
    }
  }

  Future<bool> _editLinkDialog(ConnectionLink link, Person other) async {
    final c = TextEditingController(text: link.reasons.join('\n'));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(other.fullName),
        content: TextField(
          controller: c,
          maxLines: 5,
          decoration: InputDecoration(labelText: tr('reasons')),
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
      link.reasons = c.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      return true;
    }
    return false;
  }
}

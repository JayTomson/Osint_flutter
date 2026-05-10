import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';
import '../utils.dart';
import 'info_tab.dart';
import 'connections_tab.dart';
import 'evidence_tab.dart';
import 'map_screens.dart';

class PersonScreen extends StatefulWidget {
  final String caseId;
  final String personId;
  const PersonScreen({super.key, required this.caseId, required this.personId});
  @override
  State<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends State<PersonScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  CaseFile? get _case => AppState.instance.findCase(widget.caseId);
  Person? get _person => _case?.findPerson(widget.personId);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final c = _case;
        final p = _person;
        if (c == null || p == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(p.fullName),
            actions: [
              IconButton(
                tooltip: tr('edit'),
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editHeader(context, c, p),
              ),
              IconButton(
                tooltip: tr('show_on_map'),
                icon: const Icon(Icons.map_outlined),
                onPressed: () => _showMap(context, p),
              ),
            ],
            bottom: TabBar(
              controller: _tab,
              tabs: [
                Tab(text: tr('info')),
                Tab(text: tr('connections')),
                Tab(text: tr('evidence')),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              InfoTab(caseId: widget.caseId, personId: widget.personId),
              ConnectionsTab(
                  caseId: widget.caseId, personId: widget.personId),
              EvidenceTab(
                  caseId: widget.caseId, personId: widget.personId),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editHeader(
      BuildContext context, CaseFile c, Person p) async {
    final nameC = TextEditingController(text: p.name);
    final surC = TextEditingController(text: p.surname);
    final patC = TextEditingController(text: p.patronymic);
    final notesC = TextEditingController(text: p.notes);
    final tagsC = TextEditingController(text: p.tags.join(', '));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('edit_target')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                autofocus: true,
                decoration: InputDecoration(labelText: tr('name')),
              ),
              TextField(
                controller: surC,
                decoration: InputDecoration(labelText: tr('surname')),
              ),
              TextField(
                controller: patC,
                decoration: InputDecoration(labelText: tr('patronymic')),
              ),
              TextField(
                controller: notesC,
                decoration: InputDecoration(labelText: tr('notes')),
                maxLines: 3,
              ),
              TextField(
                controller: tagsC,
                decoration: InputDecoration(
                  labelText: tr('tags'),
                  hintText: tr('tags_comma_hint'),
                ),
              ),
            ],
          ),
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
      p.name = nameC.text.trim();
      p.surname = surC.text.trim();
      p.patronymic = patC.text.trim();
      p.notes = notesC.text.trim();
      p.tags = tagsC.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await AppState.instance.persist();
    }
  }

  void _showMap(BuildContext context, Person p) {
    final coords = <dynamic>[];
    for (final cat in p.categories) {
      for (final kv in cat.entries) {
        // Import ValueDetector lazily to avoid circular deps
        // Just navigate to map screen
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MapTab(caseId: widget.caseId, personId: widget.personId),
      ),
    );
  }
}

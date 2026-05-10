part of '../main.dart';

// ============================================================================
// PERSON SCREEN — tabbed view of a single target
// ============================================================================

class PersonScreen extends StatefulWidget {
  final String caseId;
  final String personId;
  const PersonScreen(
      {super.key, required this.caseId, required this.personId});
  @override
  State<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends State<PersonScreen> {
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
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(p.fullName),
              actions: [
                IconButton(
                  tooltip: tr('edit'),
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _editBasics,
                ),
                IconButton(
                  tooltip: tr('generate_pdf'),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: _openPdfFlow,
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'delete') {
                      final ok = await showDeleteDialog(context);
                      if (ok == true) {
                        c.people.removeWhere(
                            (pp) => pp.id == widget.personId);
                        for (final pp in c.people) {
                          pp.connections.removeWhere((link) =>
                              link.targetPersonId == widget.personId);
                        }
                        await AppState.instance.persist();
                        if (!mounted) return;
                        Navigator.pop(context);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'delete', child: Text(tr('delete'))),
                  ],
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: tr('info')),
                  Tab(text: tr('connections')),
                  Tab(text: tr('evidence')),
                  Tab(text: tr('map')),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _InfoTab(person: p, onChange: _persist),
                _ConnectionsTab(
                    caseFile: c, person: p, onChange: _persist),
                _EvidenceTab(person: p, onChange: _persist),
                _MapTab(person: p),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _persist() => AppState.instance.persist();

  Future<void> _editBasics() async {
    final p = _person;
    if (p == null) return;
    final nameC = TextEditingController(text: p.name);
    final surC = TextEditingController(text: p.surname);
    final patC = TextEditingController(text: p.patronymic);
    final notesC = TextEditingController(text: p.notes);
    final tagsC = TextEditingController(text: p.tags.join(', '));
    final exp = AppState.instance.settings.experimental;
    Priority? selectedPriority = p.priority;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: Text(tr('edit_target')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameC,
                    autofocus: true,
                    decoration: InputDecoration(labelText: tr('name'))),
                TextField(
                    controller: surC,
                    decoration: InputDecoration(labelText: tr('surname'))),
                TextField(
                    controller: patC,
                    decoration:
                        InputDecoration(labelText: tr('patronymic'))),
                TextField(
                  controller: notesC,
                  decoration: InputDecoration(labelText: tr('notes')),
                  maxLines: 3,
                ),
                TextField(
                  controller: tagsC,
                  decoration: InputDecoration(
                    labelText: tr('tags'),
                    hintText: 'tag1, tag2',
                  ),
                ),
                if (exp.priority) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Priority?>(
                    value: selectedPriority,
                    decoration: InputDecoration(labelText: tr('priority')),
                    items: [
                      DropdownMenuItem<Priority?>(
                        value: null,
                        child: Text(tr('priority_none')),
                      ),
                      ...Priority.values.map(
                        (prio) => DropdownMenuItem<Priority?>(
                          value: prio,
                          child: Row(
                            children: [
                              Icon(Icons.circle,
                                  size: 10, color: prio.color),
                              const SizedBox(width: 8),
                              Text(prio.label),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setS(() => selectedPriority = v),
                  ),
                ],
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
        );
      }),
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
      if (exp.priority) p.priority = selectedPriority;
      await _persist();
    }
  }

  Future<void> _openPdfFlow() async {
    bool withConnections = false;
    bool withEvidence = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: Text(tr('pdf_options')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(tr('include_connections')),
                value: withConnections,
                onChanged: (v) => setS(() => withConnections = v),
              ),
              SwitchListTile(
                title: Text(tr('include_evidence')),
                value: withEvidence,
                onChanged: (v) => setS(() => withEvidence = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('preview'))),
          ],
        );
      }),
    );
    if (ok == true && mounted) {
      final p = _person;
      final c = _case;
      if (p == null || c == null) return;
      final bytes = await PdfBuilder.buildPersonPdf(
        p,
        caseFile: c,
        withConnections: withConnections,
        withEvidence: withEvidence,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            bytes: bytes,
            person: p,
            withEvidence: withEvidence,
          ),
        ),
      );
    }
  }
}

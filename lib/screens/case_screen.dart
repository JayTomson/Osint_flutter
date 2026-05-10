part of '../main.dart';

// ============================================================================
// CASE SCREEN — list of targets in a case
// ============================================================================

class _PersonMatch {
  final Person person;
  final List<SearchHit> hits;
  _PersonMatch(this.person, this.hits);
}

class CaseScreen extends StatefulWidget {
  final String caseId;
  const CaseScreen({super.key, required this.caseId});
  @override
  State<CaseScreen> createState() => _CaseScreenState();
}

class _CaseScreenState extends State<CaseScreen> {
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  CaseFile? get _case => AppState.instance.findCase(widget.caseId);

  List<_PersonMatch> _filtered(CaseFile c) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return c.people.map((p) => _PersonMatch(p, const [])).toList();
    return c.people
        .where((p) => personMatchesQuery(p, q))
        .map((p) => _PersonMatch(p, findPersonHits(p, q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final c = _case;
        if (c == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final list = _filtered(c);
        final exp = AppState.instance.settings.experimental;
        return Scaffold(
          appBar: AppBar(
            title: Text(c.name.isEmpty ? '—' : c.name),
            actions: [
              if (exp.globalMap)
                IconButton(
                  tooltip: tr('global_case_map'),
                  icon: const Icon(Icons.map_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => GlobalMapScreen(caseId: c.id)),
                  ),
                ),
              if (exp.casePdf)
                IconButton(
                  tooltip: tr('case_pdf'),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: () => _openCasePdf(context, c),
                ),
              IconButton(
                tooltip: tr('graph'),
                icon: const Icon(Icons.hub_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => GraphScreen(caseId: c.id)),
                ),
              ),
              IconButton(
                tooltip: tr('settings'),
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: tr('deep_search'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 350), () {
                      if (mounted) setState(() => _query = v);
                    });
                  },
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _query.isEmpty
                                ? tr('no_targets')
                                : tr('no_results'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 96),
                        itemCount: list.length,
                        itemBuilder: (context, i) => _PersonCard(
                          caseId: c.id,
                          person: list[i].person,
                          hits: list[i].hits,
                          query: _query.trim().isEmpty ? null : _query.trim(),
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddPersonDialog(context, c),
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(tr('new_target')),
          ),
        );
      },
    );
  }

  Future<void> _openCasePdf(BuildContext context, CaseFile c) async {
    bool withConnections = false;
    bool withEvidence = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: Text(tr('generate_case_pdf')),
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
      final bytes = await CasePdfBuilder.buildCasePdf(
        c,
        withConnections: withConnections,
        withEvidence: withEvidence,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CasePdfPreviewScreen(bytes: bytes, caseFile: c),
        ),
      );
    }
  }

  Future<void> _showAddPersonDialog(BuildContext context, CaseFile c) async {
    final nameC = TextEditingController();
    final surC = TextEditingController();
    final patC = TextEditingController();
    final tagsC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('new_target')),
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
                  decoration: InputDecoration(labelText: tr('patronymic'))),
              const SizedBox(height: 8),
              TextField(
                controller: tagsC,
                decoration: InputDecoration(
                  labelText: tr('tags'),
                  hintText: 'tag1, tag2',
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
              child: Text(tr('add'))),
        ],
      ),
    );
    if (ok == true) {
      final p = Person(
        name: nameC.text.trim(),
        surname: surC.text.trim(),
        patronymic: patC.text.trim(),
        tags: tagsC.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
      c.people.add(p);
      await AppState.instance.persist();
    }
  }
}

class _PersonCard extends StatefulWidget {
  final String caseId;
  final Person person;
  final List<SearchHit> hits;
  final String? query;
  const _PersonCard({
    required this.caseId,
    required this.person,
    this.hits = const [],
    this.query,
  });

  @override
  State<_PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends State<_PersonCard> {
  Future<void> _quickSetPriority(BuildContext context) async {
    const noneKey = 'none';
    final result = await showModalBottomSheet<Object>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                tr('set_priority'),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.remove_circle_outline, color: Colors.grey),
              title: Text(tr('priority_none')),
              onTap: () => Navigator.pop(ctx, noneKey),
              trailing: widget.person.priority == null
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
            ),
            ...Priority.values.map((p) => ListTile(
                  leading: Icon(Icons.circle, size: 14, color: p.color),
                  title: Text(p.label),
                  onTap: () => Navigator.pop(ctx, p),
                  trailing: widget.person.priority == p
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (result == null) return;
    final newPriority = result == noneKey ? null : result as Priority;
    widget.person.priority = newPriority;
    await AppState.instance.persist();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exp = AppState.instance.settings.experimental;
    final person = widget.person;
    final connCount = person.connections.length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PersonScreen(caseId: widget.caseId, personId: person.id),
          ),
        ),
        onLongPress: () async {
          final ok = await showDeleteDialog(context);
          if (ok == true) {
            final c = AppState.instance.findCase(widget.caseId);
            if (c == null) return;
            c.people.removeWhere((p) => p.id == person.id);
            for (final p in c.people) {
              p.connections
                  .removeWhere((link) => link.targetPersonId == person.id);
            }
            await AppState.instance.persist();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  person.initials,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (exp.priority) ...[
                      GestureDetector(
                        onTap: () async {
                          await _quickSetPriority(context);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (person.priority != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: person.priority!.color
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: person.priority!.color
                                          .withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.flag_outlined,
                                        size: 11,
                                        color: person.priority!.color),
                                    const SizedBox(width: 4),
                                    Text(
                                      person.priority!.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: person.priority!.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ] else ...[
                              Icon(Icons.add_circle_outline,
                                  size: 13,
                                  color:
                                      Colors.grey.withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Text(
                                tr('priority'),
                                style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Colors.grey.withValues(alpha: 0.5)),
                              ),
                              const SizedBox(width: 6),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      person.fullName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    // Connections count
                    if (connCount > 0)
                      Text(
                        '$connCount ${tr('connections_count')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    if (person.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: person.tags
                            .map((t) => Chip(
                                  label: Text(t,
                                      style:
                                          const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                ))
                            .toList(),
                      ),
                    ],
                    if (widget.hits.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      for (final hit in widget.hits.take(2)) ...[
                        Text(
                          hit.location,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey),
                        ),
                        if (widget.query != null)
                          _HighlightText(
                              text: hit.snippet, query: widget.query!),
                      ],
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

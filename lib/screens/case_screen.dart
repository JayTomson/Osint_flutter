import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';
import '../search.dart';
import '../utils.dart';
import 'person_screen.dart';
import 'graph_screen.dart';
import 'map_screens.dart';

class _PersonMatch {
  final Person person;
  final List<SearchHit> hits;
  const _PersonMatch(this.person, this.hits);
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
    if (q.isEmpty) return c.people.map((p) => _PersonMatch(p, [])).toList();
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
            title: Text(c.name),
            actions: [
              if (exp.globalMap)
                IconButton(
                  tooltip: tr('global_case_map'),
                  icon: const Icon(Icons.map_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            GlobalMapScreen(caseId: widget.caseId)),
                  ),
                ),
              if (exp.casePdf)
                IconButton(
                  tooltip: tr('case_pdf'),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: () => _openCasePdfFlow(c),
                ),
              IconButton(
                tooltip: tr('graph'),
                icon: const Icon(Icons.account_tree_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          GraphScreen(caseId: widget.caseId)),
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
                    _debounce =
                        Timer(const Duration(milliseconds: 350), () {
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
                        padding:
                            const EdgeInsets.fromLTRB(8, 4, 8, 96),
                        itemCount: list.length,
                        itemBuilder: (context, i) => _PersonCard(
                          caseFile: c,
                          person: list[i].person,
                          hits: list[i].hits,
                          query: _query.trim().isEmpty
                              ? null
                              : _query.trim(),
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addPerson(c),
            icon: const Icon(Icons.person_add_outlined),
            label: Text(tr('new_target')),
          ),
        );
      },
    );
  }

  Future<void> _addPerson(CaseFile c) async {
    final nameC = TextEditingController();
    final surC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('new_target')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              autofocus: true,
              decoration: InputDecoration(labelText: tr('name')),
              onSubmitted: (_) => Navigator.pop(ctx, true),
            ),
            TextField(
              controller: surC,
              decoration: InputDecoration(labelText: tr('surname')),
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
    if (ok == true && (nameC.text.trim().isNotEmpty || surC.text.trim().isNotEmpty)) {
      final p = Person(name: nameC.text.trim(), surname: surC.text.trim());
      c.people.add(p);
      await AppState.instance.persist();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PersonScreen(caseId: c.id, personId: p.id),
          ),
        );
      }
    }
  }

  Future<void> _openCasePdfFlow(CaseFile c) async {
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
      // Import here to avoid circular dependency at file level
      // ignore: implementation_imports
      final bytes = await _buildCasePdfDynamic(
          c, withConnections: withConnections, withEvidence: withEvidence);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _CasePdfPreviewRouteWrapper(
              bytes: bytes, caseFile: c),
        ),
      );
    }
  }
}

// Thin wrapper to import CasePdfBuilder lazily
Future<List<int>> _buildCasePdfDynamic(CaseFile c,
    {required bool withConnections, required bool withEvidence}) async {
  // This call is resolved at runtime; pdf_builder.dart must be imported
  // in the actual implementation or inlined here.
  // To avoid circular import, we delegate through the pdf module.
  throw UnimplementedError(
      'Wire up CasePdfBuilder.buildCasePdf() here from pdf/pdf_builder.dart');
}

class _CasePdfPreviewRouteWrapper extends StatelessWidget {
  final List<int> bytes;
  final CaseFile caseFile;
  const _CasePdfPreviewRouteWrapper(
      {required this.bytes, required this.caseFile});
  @override
  Widget build(BuildContext context) => const Placeholder();
}

// ---------------------------------------------------------------------------

class _PersonCard extends StatefulWidget {
  final CaseFile caseFile;
  final Person person;
  final List<SearchHit> hits;
  final String? query;
  const _PersonCard({
    required this.caseFile,
    required this.person,
    this.hits = const [],
    this.query,
  });

  @override
  State<_PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends State<_PersonCard> {
  Person get person => widget.person;

  Future<void> _quickSetPriority(BuildContext context) async {
    final selected = await showDialog<Priority?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr('set_priority')),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(tr('priority_none')),
          ),
          ...Priority.values.map(
            (p) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, p),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 10, color: p.color),
                  const SizedBox(width: 8),
                  Text(p.label),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    setState(() => person.priority = selected);
    await AppState.instance.persist();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exp = AppState.instance.settings.experimental;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PersonScreen(
                caseId: widget.caseFile.id, personId: person.id),
          ),
        ),
        onLongPress: () async {
          final action = await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(tr('edit')),
                    onTap: () => Navigator.pop(ctx, 'edit'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline,
                        color: Colors.red),
                    title: Text(tr('delete'),
                        style: const TextStyle(color: Colors.red)),
                    onTap: () => Navigator.pop(ctx, 'delete'),
                  ),
                ],
              ),
            ),
          );
          if (action == 'delete') {
            if (!context.mounted) return;
            final ok = await showDeleteDialog(context);
            if (ok == true) {
              final c = widget.caseFile;
              c.people.removeWhere((p) => p.id == person.id);
              for (final p in c.people) {
                p.connections.removeWhere(
                    (link) => link.targetPersonId == person.id);
              }
              await AppState.instance.persist();
            }
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
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.grey.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.grey
                                          .withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.flag_outlined,
                                        size: 11, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      tr('set_priority'),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            person.fullName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final t in person.tags)
                          Chip(
                            label: Text(t),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (person.connections.isNotEmpty)
                          Chip(
                            label: Text(
                                '${person.connections.length} ${tr('connections_count')}'),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                    if (widget.hits.isNotEmpty &&
                        widget.query != null &&
                        widget.query!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final hit
                                in widget.hits.take(2)) ...[
                              Text(
                                '${tr("found_in")}: ${hit.location}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              HighlightText(
                                  text: hit.snippet,
                                  query: widget.query!),
                              const SizedBox(height: 2),
                            ],
                          ],
                        ),
                      ),
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

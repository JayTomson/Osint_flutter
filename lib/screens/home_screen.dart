part of '../main.dart';

// ============================================================================
// HOME SCREEN — list of cases
// ============================================================================

class _CaseMatch {
  final CaseFile caseFile;
  final String? hitPersonName;
  final List<SearchHit> personHits;
  const _CaseMatch(this.caseFile, {this.hitPersonName, this.personHits = const []});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  List<_CaseMatch> get _filtered {
    final q = _query.trim().toLowerCase();
    final all = AppState.instance.cases;
    if (q.isEmpty) return all.map((c) => _CaseMatch(c)).toList();
    final result = <_CaseMatch>[];
    for (final c in all) {
      if (c.name.toLowerCase().contains(q) ||
          FuzzySearch.matches(q, c.name)) {
        result.add(_CaseMatch(c));
        continue;
      }
      bool caseTagMatch = false;
      for (final t in c.tags) {
        if (FuzzySearch.matches(q, t)) {
          caseTagMatch = true;
          break;
        }
      }
      if (caseTagMatch) {
        result.add(_CaseMatch(c));
        continue;
      }
      Person? matchedPerson;
      List<SearchHit> hits = [];
      for (final p in c.people) {
        if (personMatchesQuery(p, q)) {
          matchedPerson = p;
          hits = findPersonHits(p, q);
          break;
        }
      }
      if (matchedPerson != null) {
        result.add(_CaseMatch(c,
            hitPersonName: matchedPerson.fullName, personHits: hits));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final list = _filtered;
        return Scaffold(
          appBar: AppBar(
            title: Text(tr('cases')),
            actions: [
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
                                ? tr('no_cases')
                                : tr('no_results'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 96),
                        itemCount: list.length,
                        itemBuilder: (context, i) => _CaseCard(
                          caseMatch: list[i],
                          query: _query.trim().isEmpty ? null : _query.trim(),
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddCaseDialog(context),
            icon: const Icon(Icons.create_new_folder_outlined),
            label: Text(tr('new_case')),
          ),
        );
      },
    );
  }

  Future<void> _showAddCaseDialog(BuildContext context) async {
    final nameC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('new_case')),
        content: TextField(
          controller: nameC,
          autofocus: true,
          decoration: InputDecoration(labelText: tr('case_name')),
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
    if (ok == true && nameC.text.trim().isNotEmpty) {
      final c = CaseFile(name: nameC.text.trim());
      AppState.instance.cases.add(c);
      await AppState.instance.persist();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CaseScreen(caseId: c.id)),
        );
      }
    }
  }
}

class _CaseCard extends StatelessWidget {
  final _CaseMatch caseMatch;
  final String? query;
  const _CaseCard({required this.caseMatch, this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caseFile = caseMatch.caseFile;
    final exp = AppState.instance.settings.experimental;
    final connTotal =
        caseFile.people.fold<int>(0, (s, p) => s + p.connections.length) ~/ 2;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CaseScreen(caseId: caseFile.id)),
        ),
        onLongPress: () async {
          final items = <String>['rename', 'delete'];
          if (exp.caseTags) items.insert(0, 'tags');
          final action = await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (exp.caseTags)
                    ListTile(
                      leading: const Icon(Icons.label_outline),
                      title: Text(tr('edit_case_tags')),
                      onTap: () => Navigator.pop(ctx, 'tags'),
                    ),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(tr('rename_case')),
                    onTap: () => Navigator.pop(ctx, 'rename'),
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
              AppState.instance.cases.removeWhere((c) => c.id == caseFile.id);
              await AppState.instance.persist();
            }
          } else if (action == 'rename') {
            if (!context.mounted) return;
            final c = TextEditingController(text: caseFile.name);
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(tr('rename_case')),
                content: TextField(
                  controller: c,
                  autofocus: true,
                  decoration: InputDecoration(labelText: tr('case_name')),
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
              caseFile.name = c.text.trim();
              await AppState.instance.persist();
            }
          } else if (action == 'tags') {
            if (!context.mounted) return;
            final tagsC = TextEditingController(text: caseFile.tags.join(', '));
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(tr('edit_case_tags')),
                content: TextField(
                  controller: tagsC,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: tr('tags'),
                    hintText: tr('case_tags_hint'),
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
              caseFile.tags = tagsC.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              await AppState.instance.persist();
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.folder_special_outlined,
                    size: 28,
                    color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caseFile.name.isEmpty ? '—' : caseFile.name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Chip(
                          label: Text(
                              '${caseFile.people.length} ${tr('targets_count')}'),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        if (connTotal > 0)
                          Chip(
                            label: Text(
                                '$connTotal ${tr('connections_count')}'),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (exp.caseTags)
                          for (final t in caseFile.tags)
                            Chip(
                              label: Text(t),
                              avatar: const Icon(Icons.label_outline, size: 14),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                      ],
                    ),
                    if (caseMatch.hitPersonName != null) ...[
                      const SizedBox(height: 4),
                      _SearchHitBadge(
                        personName: caseMatch.hitPersonName!,
                        hits: caseMatch.personHits,
                        query: query ?? '',
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

class _SearchHitBadge extends StatelessWidget {
  final String personName;
  final List<SearchHit> hits;
  final String query;
  const _SearchHitBadge(
      {required this.personName, required this.hits, required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = hits.take(2).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${tr("found_in")}: $personName',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.secondary,
            ),
          ),
          for (final hit in top) ...[
            Text(
              hit.location,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            _HighlightText(text: hit.snippet, query: query),
          ],
        ],
      ),
    );
  }
}

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  const _HighlightText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lower = text.toLowerCase();
    final qLower = query.toLowerCase().trim();
    final idx = lower.indexOf(qLower);
    if (idx < 0 || qLower.isEmpty) {
      return Text(text,
          style: const TextStyle(fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis);
    }
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: 12),
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + qLower.length),
            style: TextStyle(
              backgroundColor:
                  theme.colorScheme.tertiary.withValues(alpha: 0.35),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (idx + qLower.length < text.length)
            TextSpan(text: text.substring(idx + qLower.length)),
        ],
      ),
    );
  }
}

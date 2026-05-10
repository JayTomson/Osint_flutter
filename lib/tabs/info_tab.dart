part of '../main.dart';

// ============================================================================
// INFO TAB (categories with reorderable key-values; also reorder categories)
// ============================================================================

class _InfoTab extends StatefulWidget {
  final Person person;
  final Future<void> Function() onChange;
  const _InfoTab({required this.person, required this.onChange});
  @override
  State<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<_InfoTab> {
  @override
  Widget build(BuildContext context) {
    final p = widget.person;
    return Stack(
      children: [
        if (p.categories.isEmpty)
          Center(
            child: Text(tr('no_categories_yet'),
                style: const TextStyle(color: Colors.grey)),
          )
        else
          ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: p.categories.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex--;
              setState(() {
                final item = p.categories.removeAt(oldIndex);
                p.categories.insert(newIndex, item);
              });
              await widget.onChange();
            },
            itemBuilder: (context, i) => _CategoryCard(
              key: ValueKey(p.categories[i].id),
              category: p.categories[i],
              onDelete: () async {
                setState(() => p.categories.removeAt(i));
                await widget.onChange();
              },
              onChange: () async {
                setState(() {});
                await widget.onChange();
              },
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'infoFab',
            onPressed: _addCategory,
            icon: const Icon(Icons.add),
            label: Text(tr('add_category')),
          ),
        ),
      ],
    );
  }

  Future<void> _addCategory() async {
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
    if (ok == true) {
      setState(() =>
          widget.person.categories.add(CategoryBlock(name: c.text.trim())));
      await widget.onChange();
    }
  }
}

class _CategoryCard extends StatefulWidget {
  final CategoryBlock category;
  final Future<void> Function() onDelete;
  final Future<void> Function() onChange;
  const _CategoryCard(
      {super.key,
      required this.category,
      required this.onDelete,
      required this.onChange});
  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: 0,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.drag_handle, color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: Text(
                    cat.name.isEmpty ? '—' : cat.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: _renameCategory,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  onPressed: () async {
                    final ok = await showDeleteDialog(context);
                    if (ok == true) {
                      await widget.onDelete();
                    }
                  },
                ),
              ],
            ),
            if (cat.entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('—',
                    style: TextStyle(color: Colors.grey.withValues(alpha: 0.6))),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cat.entries.length,
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) newIndex--;
                  setState(() {
                    final item = cat.entries.removeAt(oldIndex);
                    cat.entries.insert(newIndex, item);
                  });
                  await widget.onChange();
                },
                itemBuilder: (context, i) => _KvTile(
                  key: ValueKey(cat.entries[i].id),
                  index: i,
                  kv: cat.entries[i],
                  onEdit: () => _editKv(cat.entries[i]),
                  onDelete: () async {
                    setState(() => cat.entries.removeAt(i));
                    await widget.onChange();
                  },
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text(tr('add_kv')),
                onPressed: _addKv,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameCategory() async {
    final c = TextEditingController(text: widget.category.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('rename_category')),
        content: TextField(
            controller: c,
            decoration: InputDecoration(labelText: tr('category_name'))),
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
      setState(() => widget.category.name = c.text.trim());
      await widget.onChange();
    }
  }

  Future<void> _addKv() async {
    final kv = KeyValue();
    final added = await _kvDialog(kv);
    if (added) {
      setState(() => widget.category.entries.add(kv));
      await widget.onChange();
    }
  }

  Future<void> _editKv(KeyValue kv) async {
    final ok = await _kvDialog(kv);
    if (ok) {
      setState(() {});
      await widget.onChange();
    }
  }

  Future<bool> _kvDialog(KeyValue kv) async {
    final keyC = TextEditingController(text: kv.key);
    final valC = TextEditingController(text: kv.value);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('add_kv')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: keyC,
                  decoration: InputDecoration(labelText: tr('key'))),
              TextField(
                controller: valC,
                decoration: InputDecoration(labelText: tr('value')),
                maxLines: null,
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
      kv.key = keyC.text.trim();
      kv.value = valC.text;
      return true;
    }
    return false;
  }
}

class _KvTile extends StatelessWidget {
  final int index;
  final KeyValue kv;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _KvTile({
    super.key,
    required this.index,
    required this.kv,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final coord = ValueDetector.extractCoord(kv.value);
    final phone = ValueDetector.extractPhone(kv.value);
    final card = ValueDetector.extractCard(kv.value);
    final mark = ValueDetector.matchedCustomMark(kv.value);

    final actions = <Widget>[];

    void addCopyBtn(String text, {String? label}) {
      actions.add(IconButton(
        tooltip: label == null ? tr('copy') : '${tr('copy')}: $label',
        icon: const Icon(Icons.copy, size: 18),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: text));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(tr('copied')),
                  duration: const Duration(seconds: 1)),
            );
          }
        },
      ));
    }

    if (coord != null) {
      actions.add(IconButton(
        tooltip: tr('open_on_map'),
        icon: const Icon(Icons.place_outlined, size: 20),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SingleMarkerMapScreen(
              point: coord,
              label: kv.key.isEmpty
                  ? '${coord.latitude}, ${coord.longitude}'
                  : kv.key,
            ),
          ),
        ),
      ));
      addCopyBtn('${coord.latitude}, ${coord.longitude}', label: 'coords');
    }
    if (phone != null) addCopyBtn(phone, label: 'phone');
    if (card != null) addCopyBtn(card, label: 'card');
    if (mark != null) addCopyBtn(kv.value, label: 'mark $mark');

    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      dense: true,
      leading: ReorderableDragStartListener(
        index: index,
        child: const Padding(
          padding: EdgeInsets.only(left: 6),
          child: Icon(Icons.drag_indicator, size: 18, color: Colors.grey),
        ),
      ),
      title: Text(
        kv.key.isEmpty ? '—' : kv.key,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
      subtitle: _ValueText(value: kv.value),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...actions,
          IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEdit),
          IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete),
        ],
      ),
    );
  }
}

class _ValueText extends StatelessWidget {
  final String value;
  const _ValueText({required this.value});
  @override
  Widget build(BuildContext context) {
    final mark = ValueDetector.matchedCustomMark(value);
    if (mark == null || value.isEmpty) {
      return Text(value, style: const TextStyle(fontSize: 15));
    }
    final v = value.trimLeft();
    final remaining = v.substring(mark.length);
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: 15),
        children: [
          TextSpan(text: mark, style: const TextStyle(color: Colors.grey)),
          TextSpan(text: remaining),
        ],
      ),
    );
  }
}

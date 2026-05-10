part of '../main.dart';

// ============================================================================
// MARKS SCREEN
// ============================================================================

class MarksScreen extends StatefulWidget {
  const MarksScreen({super.key});
  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  @override
  Widget build(BuildContext context) {
    final marks = AppState.instance.settings.marks;
    return Scaffold(
      appBar: AppBar(title: Text(tr('custom_marks'))),
      body: marks.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  tr('no_marks_yet'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
              itemCount: marks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (ctx, i) {
                final m = marks[i];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(child: Text(m.char)),
                    title: Text(m.label.isEmpty ? m.char : m.label),
                    subtitle: m.label.isEmpty ? null : Text(m.char),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editMark(i, m),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () async {
                            final ok = await showDeleteDialog(context);
                            if (ok == true) {
                              setState(() => marks.removeAt(i));
                              await AppState.instance.persistSettingsOnly();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMark,
        icon: const Icon(Icons.add),
        label: Text(tr('add_mark')),
      ),
    );
  }

  Future<void> _addMark() async {
    final charC = TextEditingController();
    final labelC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('add_mark')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: charC,
              autofocus: true,
              decoration: InputDecoration(labelText: tr('mark_char')),
              maxLength: 4,
            ),
            TextField(
              controller: labelC,
              decoration: InputDecoration(labelText: tr('mark_label')),
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
    if (ok == true && charC.text.trim().isNotEmpty) {
      setState(() {
        AppState.instance.settings.marks.add(
          CustomMark(char: charC.text.trim(), label: labelC.text.trim()),
        );
      });
      await AppState.instance.persistSettingsOnly();
    }
  }

  Future<void> _editMark(int index, CustomMark mark) async {
    final charC = TextEditingController(text: mark.char);
    final labelC = TextEditingController(text: mark.label);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('add_mark')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: charC,
              autofocus: true,
              decoration: InputDecoration(labelText: tr('mark_char')),
              maxLength: 4,
            ),
            TextField(
              controller: labelC,
              decoration: InputDecoration(labelText: tr('mark_label')),
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
    if (ok == true && charC.text.trim().isNotEmpty) {
      setState(() {
        mark.char = charC.text.trim();
        mark.label = labelC.text.trim();
      });
      await AppState.instance.persistSettingsOnly();
    }
  }
}

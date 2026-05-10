part of '../main.dart';

// ============================================================================
// EVIDENCE TAB
// ============================================================================

class _EvidenceTab extends StatefulWidget {
  final Person person;
  final Future<void> Function() onChange;
  const _EvidenceTab({required this.person, required this.onChange});
  @override
  State<_EvidenceTab> createState() => _EvidenceTabState();
}

class _EvidenceTabState extends State<_EvidenceTab> {
  @override
  Widget build(BuildContext context) {
    final files = widget.person.evidenceFiles;
    return Stack(
      children: [
        if (files.isEmpty)
          Center(
            child: Text(tr('no_evidence_yet'),
                style: const TextStyle(color: Colors.grey)),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: files.length,
            itemBuilder: (ctx, i) => _FileTile(
              file: files[i],
              onDelete: () async {
                setState(() => files.removeAt(i));
                await widget.onChange();
              },
              onNote: (note) async {
                files[i].note = note;
                setState(() {});
                await widget.onChange();
              },
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'evidenceFab',
            onPressed: _pickFile,
            icon: const Icon(Icons.attach_file),
            label: Text(tr('add_file')),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (res == null) return;
    final docDir = AppState.instance.docsDir;
    for (final picked in res.files) {
      if (picked.path == null) continue;
      final src = File(picked.path!);
      final dest = File(
          '${docDir.path}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}');
      await src.copy(dest.path);
      setState(() => widget.person.evidenceFiles.add(
            EvidenceFile(
              path: dest.path,
              name: picked.name,
              mimeType: _guessMime(picked.extension ?? ''),
            ),
          ));
    }
    await widget.onChange();
  }

  String _guessMime(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }
}

class _FileTile extends StatelessWidget {
  final EvidenceFile file;
  final VoidCallback onDelete;
  final void Function(String note) onNote;
  const _FileTile(
      {required this.file, required this.onDelete, required this.onNote});

  @override
  Widget build(BuildContext context) {
    final isImage = file.mimeType.startsWith('image/');
    final exists = File(file.path).existsSync();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage && exists) _imagePreview(),
          ListTile(
            leading: Icon(_fileIcon()),
            title: Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: file.note.isNotEmpty ? Text(file.note) : null,
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'open') _openFile(context);
                if (v == 'share') _shareFile(context);
                if (v == 'note') _editNote(context);
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'open', child: Text(tr('open'))),
                PopupMenuItem(value: 'share', child: Text(tr('share'))),
                PopupMenuItem(value: 'note', child: Text(tr('edit_note'))),
                PopupMenuItem(value: 'delete', child: Text(tr('delete'))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePreview() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: Image.file(
        File(file.path),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  IconData _fileIcon() {
    if (file.mimeType.startsWith('image/')) return Icons.image_outlined;
    if (file.mimeType.startsWith('video/')) return Icons.videocam_outlined;
    if (file.mimeType == 'application/pdf') return Icons.picture_as_pdf_outlined;
    if (file.mimeType.startsWith('text/')) return Icons.text_snippet_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Future<void> _openFile(BuildContext context) async {
    final f = File(file.path);
    if (!f.existsSync()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('file_not_found'))),
        );
      }
      return;
    }
    try {
      await OpenFilex.open(file.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _shareFile(BuildContext context) async {
    final f = File(file.path);
    if (!f.existsSync()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('file_not_found'))),
        );
      }
      return;
    }
    await Share.shareXFiles([XFile(file.path)], text: file.name);
  }

  Future<void> _editNote(BuildContext context) async {
    final c = TextEditingController(text: file.note);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('edit_note')),
        content: TextField(
          controller: c,
          maxLines: 4,
          decoration: InputDecoration(labelText: tr('note')),
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
    if (ok == true) onNote(c.text.trim());
  }
}

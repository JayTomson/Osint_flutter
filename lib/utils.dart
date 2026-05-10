import 'package:flutter/material.dart';
import 'l10n.dart';

Future<bool?> showDeleteDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr('confirm_delete')),
      content: Text(tr('this_action_cannot_be_undone')),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(tr('delete')),
        ),
      ],
    ),
  );
}

bool isImagePath(String path) {
  final p = path.toLowerCase();
  return p.endsWith('.jpg') ||
      p.endsWith('.jpeg') ||
      p.endsWith('.png') ||
      p.endsWith('.webp') ||
      p.endsWith('.gif') ||
      p.endsWith('.bmp');
}

class HighlightText extends StatelessWidget {
  final String text;
  final String query;
  const HighlightText({super.key, required this.text, required this.query});

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

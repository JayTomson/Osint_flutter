part of '../main.dart';

// ============================================================================
// SHARED WIDGETS / DIALOGS
// ============================================================================

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

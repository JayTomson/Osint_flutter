import 'package:flutter/material.dart';
import '../l10n/localization.dart';

enum Priority { high, medium, low }

extension PriorityExt on Priority {
  String get label {
    switch (this) {
      case Priority.high:
        return tr('priority_high');
      case Priority.medium:
        return tr('priority_medium');
      case Priority.low:
        return tr('priority_low');
    }
  }

  Color get color {
    switch (this) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }
}

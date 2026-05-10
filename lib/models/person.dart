import 'package:uuid/uuid.dart';
import '../l10n/localization.dart';
import 'category_block.dart';
import 'connection_link.dart';
import 'evidence_item.dart';
import 'priority.dart';

const _uuid = Uuid();

class Person {
  String id;
  String name;
  String surname;
  String patronymic;
  String notes;
  List<String> tags;
  List<CategoryBlock> categories;
  List<ConnectionLink> connections;
  List<EvidenceItem> evidence;
  Priority? priority;

  Person({
    String? id,
    this.name = '',
    this.surname = '',
    this.patronymic = '',
    this.notes = '',
    List<String>? tags,
    List<CategoryBlock>? categories,
    List<ConnectionLink>? connections,
    List<EvidenceItem>? evidence,
    this.priority,
  })  : id = id ?? _uuid.v4(),
        tags = tags ?? [],
        categories = categories ?? [],
        connections = connections ?? [],
        evidence = evidence ?? [];

  String get fullName {
    final parts = [name, surname, patronymic].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? tr('no_name') : parts.join(' ');
  }

  String get initials {
    String firstChar(String s) => s.isEmpty ? '' : s[0].toUpperCase();
    final s = '${firstChar(name)}${firstChar(surname)}';
    return s.isEmpty ? '?' : s;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'surname': surname,
        'patronymic': patronymic,
        'notes': notes,
        'tags': tags,
        'categories': categories.map((e) => e.toJson()).toList(),
        'connections': connections.map((e) => e.toJson()).toList(),
        'evidence': evidence.map((e) => e.toJson()).toList(),
        'priority': priority?.name,
      };

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        id: j['id'],
        name: j['name'] ?? '',
        surname: j['surname'] ?? '',
        patronymic: j['patronymic'] ?? '',
        notes: j['notes'] ?? '',
        tags: ((j['tags'] as List?) ?? []).cast<String>(),
        categories: ((j['categories'] as List?) ?? [])
            .map((e) => CategoryBlock.fromJson(e))
            .toList(),
        connections: ((j['connections'] as List?) ?? [])
            .map((e) => ConnectionLink.fromJson(e))
            .toList(),
        evidence: ((j['evidence'] as List?) ?? [])
            .map((e) => EvidenceItem.fromJson(e))
            .toList(),
        priority: j['priority'] != null
            ? Priority.values.firstWhere(
                (p) => p.name == j['priority'],
                orElse: () => Priority.medium,
              )
            : null,
      );

  Iterable<String> searchHaystack() sync* {
    yield name;
    yield surname;
    yield patronymic;
    yield notes;
    for (final t in tags) yield t;
    for (final c in categories) {
      yield c.name;
      for (final kv in c.entries) {
        yield kv.key;
        yield kv.value;
      }
    }
    for (final e in evidence) yield e.description;
    for (final c in connections) {
      for (final r in c.reasons) yield r;
    }
  }
}

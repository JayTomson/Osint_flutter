import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'l10n.dart';

const _uuid = Uuid();

class KeyValue {
  String id;
  String key;
  String value;
  KeyValue({String? id, this.key = '', this.value = ''})
      : id = id ?? _uuid.v4();
  Map<String, dynamic> toJson() => {'id': id, 'k': key, 'v': value};
  factory KeyValue.fromJson(Map<String, dynamic> j) =>
      KeyValue(id: j['id'], key: j['k'] ?? '', value: j['v'] ?? '');
}

class CategoryBlock {
  String id;
  String name;
  List<KeyValue> entries;
  CategoryBlock({String? id, this.name = '', List<KeyValue>? entries})
      : id = id ?? _uuid.v4(),
        entries = entries ?? [];
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'entries': entries.map((e) => e.toJson()).toList(),
      };
  factory CategoryBlock.fromJson(Map<String, dynamic> j) => CategoryBlock(
        id: j['id'],
        name: j['name'] ?? '',
        entries: ((j['entries'] as List?) ?? [])
            .map((e) => KeyValue.fromJson(e))
            .toList(),
      );
}

class ConnectionLink {
  String id;
  String targetPersonId;
  List<String> reasons;
  ConnectionLink(
      {String? id, required this.targetPersonId, List<String>? reasons})
      : id = id ?? _uuid.v4(),
        reasons = reasons ?? [];
  Map<String, dynamic> toJson() =>
      {'id': id, 'pid': targetPersonId, 'reasons': reasons};
  factory ConnectionLink.fromJson(Map<String, dynamic> j) => ConnectionLink(
        id: j['id'],
        targetPersonId: j['pid'] ?? '',
        reasons: ((j['reasons'] as List?) ?? []).cast<String>(),
      );
}

class EvidenceItem {
  String id;
  String description;
  List<String> filePaths;
  EvidenceItem({String? id, this.description = '', List<String>? filePaths})
      : id = id ?? _uuid.v4(),
        filePaths = filePaths ?? [];
  Map<String, dynamic> toJson() =>
      {'id': id, 'desc': description, 'files': filePaths};
  factory EvidenceItem.fromJson(Map<String, dynamic> j) => EvidenceItem(
        id: j['id'],
        description: j['desc'] ?? '',
        filePaths: ((j['files'] as List?) ?? []).cast<String>(),
      );
}

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
    final parts =
        [name, surname, patronymic].where((s) => s.isNotEmpty).toList();
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

class CaseFile {
  String id;
  String name;
  List<Person> people;
  List<String> tags;

  CaseFile({
    String? id,
    this.name = '',
    List<Person>? people,
    List<String>? tags,
  })  : id = id ?? _uuid.v4(),
        people = people ?? [],
        tags = tags ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'people': people.map((p) => p.toJson()).toList(),
        'tags': tags,
      };

  factory CaseFile.fromJson(Map<String, dynamic> j) => CaseFile(
        id: j['id'],
        name: j['name'] ?? '',
        people: ((j['people'] as List?) ?? [])
            .map((e) => Person.fromJson(e))
            .toList(),
        tags: ((j['tags'] as List?) ?? []).cast<String>(),
      );

  Person? findPerson(String personId) {
    for (final p in people) {
      if (p.id == personId) return p;
    }
    return null;
  }
}

class CustomMark {
  String char;
  String label;
  CustomMark({required this.char, this.label = ''});
  Map<String, dynamic> toJson() => {'c': char, 'l': label};
  factory CustomMark.fromJson(Map<String, dynamic> j) =>
      CustomMark(char: j['c'] ?? '', label: j['l'] ?? '');
}

enum AppTheme { light, dark, amoled }

class ExperimentalFeatures {
  bool priority;
  bool globalMap;
  bool exportGraphPng;
  bool caseTags;
  bool casePdf;
  bool exportMapPng;

  ExperimentalFeatures({
    this.priority = false,
    this.globalMap = false,
    this.exportGraphPng = false,
    this.caseTags = false,
    this.casePdf = false,
    this.exportMapPng = false,
  });

  Map<String, dynamic> toJson() => {
        'priority': priority,
        'globalMap': globalMap,
        'exportGraphPng': exportGraphPng,
        'caseTags': caseTags,
        'casePdf': casePdf,
        'exportMapPng': exportMapPng,
      };

  factory ExperimentalFeatures.fromJson(Map<String, dynamic> j) =>
      ExperimentalFeatures(
        priority: j['priority'] as bool? ?? false,
        globalMap: j['globalMap'] as bool? ?? false,
        exportGraphPng: j['exportGraphPng'] as bool? ?? false,
        caseTags: j['caseTags'] as bool? ?? false,
        casePdf: j['casePdf'] as bool? ?? false,
        exportMapPng: j['exportMapPng'] as bool? ?? false,
      );
}

class Settings {
  AppTheme theme;
  String language;
  List<CustomMark> marks;
  ExperimentalFeatures experimental;

  Settings({
    this.theme = AppTheme.dark,
    this.language = 'ru',
    List<CustomMark>? marks,
    ExperimentalFeatures? experimental,
  })  : marks = marks ?? [],
        experimental = experimental ?? ExperimentalFeatures();

  Map<String, dynamic> toJson() => {
        'theme': theme.name,
        'language': language,
        'marks': marks.map((e) => e.toJson()).toList(),
        'experimental': experimental.toJson(),
      };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        theme: AppTheme.values.firstWhere(
          (t) => t.name == (j['theme'] ?? 'dark'),
          orElse: () => AppTheme.dark,
        ),
        language: j['language'] ?? 'ru',
        marks: ((j['marks'] as List?) ?? [])
            .map((e) => CustomMark.fromJson(e))
            .toList(),
        experimental: j['experimental'] != null
            ? ExperimentalFeatures.fromJson(
                j['experimental'] as Map<String, dynamic>)
            : ExperimentalFeatures(),
      );
}

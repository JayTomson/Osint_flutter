// OSINT V — Cases-based OSINT data collection app
// Top-level entity is a "Case" (Дело). Each case contains its own targets
// (people / goals), connections graph, and evidence.
//
// Single-file Flutter app. Pair with the bundled pubspec.yaml.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

// ============================================================================
// MAIN
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.init();
  runApp(const OsintApp());
}

// ============================================================================
// LOCALIZATION
// ============================================================================

class L10n {
  static const Map<String, Map<String, String>> _t = {
    'en': {
      'app_title': 'OSINT V',
      'cases': 'Cases',
      'new_case': 'New case',
      'case_name': 'Case name',
      'no_cases': 'No cases yet. Tap + to create one.',
      'targets': 'Targets',
      'new_target': 'New target',
      'edit_target': 'Edit target',
      'name': 'Name',
      'surname': 'Surname',
      'patronymic': 'Patronymic',
      'notes': 'Notes',
      'tags': 'Tags',
      'add_tag': 'Add tag',
      'tag_name': 'Tag name',
      'deep_search': 'Deep search...',
      'no_targets': 'No targets in this case yet. Tap + to add one.',
      'no_results': 'No results.',
      'settings': 'Settings',
      'theme': 'Theme',
      'light': 'Light',
      'dark': 'Dark',
      'amoled': 'AMOLED',
      'language': 'Language',
      'storage_path': 'Storage path',
      'export_json': 'Export JSON',
      'import_json': 'Import JSON',
      'export_db': 'Export database (SQLite .db)',
      'about': 'About',
      'disclaimer':
          'The author bears no responsibility for the use of this application. '
              'All data is stored locally on your device. Use it lawfully.',
      'tutorial': 'Guide',
      'tutorial_text':
          '• Cases: the home screen lists cases. Tap + to create one (only name required). Open a case to see its targets.\n'
              '• Targets: tap + inside a case to add a target. Open it — four tabs: Info, Connections, Evidence, Map.\n'
              '• Target priority: set a priority (High / Medium / Low) when editing a target. You can also change it quickly from the target card.\n'
              '• Categories & fields: in the Info tab tap "+ Category". Inside, add key-value pairs. Long-press to drag and reorder.\n'
              '• Smart copy: phones, card numbers (16 digits), and coordinates are auto-detected and get a copy button. Add custom marks in Settings.\n'
              '• Map: values containing coordinates (e.g. 50.45, 30.52) get a map button automatically.\n'
              '• Connections: Connections tab → link another target from the same case with a reason. Tap it to open that target directly.\n'
              '• Graph: the graph button in the case header shows a visual map of all connections.\n'
              '• Search: the search field searches all fields, categories, tags, and notes with fuzzy matching.',
      'custom_marks': 'Custom marks',
      'custom_marks_subtitle': 'Manage custom copy-marks',
      'no_marks_yet': 'No custom marks yet.',
      'add_mark': 'Add mark',
      'mark_char': 'Mark character',
      'mark_label': 'Label (optional)',
      'info': 'Info',
      'connections': 'Connections',
      'evidence': 'Evidence',
      'map': 'Map',
      'add_category': 'Add category',
      'category_name': 'Category name',
      'add_kv': 'Add key-value',
      'key': 'Key',
      'value': 'Value',
      'add_connection': 'Add connection',
      'select_person': 'Select person',
      'reasons': 'Reasons (one per line)',
      'add_evidence': 'Add evidence',
      'pick_files': 'Pick files',
      'description': 'Description',
      'generate_pdf': 'Generate PDF',
      'pdf_options': 'PDF options',
      'include_connections': 'Include connections',
      'include_evidence': 'Include evidence',
      'preview': 'Preview',
      'share': 'Share',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'confirm_delete': 'Delete this item?',
      'this_action_cannot_be_undone': 'This action cannot be undone.',
      'edit': 'Edit',
      'rename': 'Rename',
      'open': 'Open',
      'copy': 'Copy',
      'copied': 'Copied',
      'open_on_map': 'Open on map',
      'graph': 'Connections graph',
      'graph_filter': 'Filter by reason',
      'all_reasons': 'All reasons',
      'no_connections_yet': 'No connections yet.',
      'no_evidence_yet': 'No evidence yet.',
      'no_categories_yet': 'No categories yet.',
      'add': 'Add',
      'add_target': 'Add target',
      'add_case': 'Add case',
      'connections_count': 'connections',
      'targets_count': 'targets',
      'no_target_marker': 'No coordinates found in this target.',
      'storage_dir_info': 'Application documents directory',
      'reset_db': 'Reset database',
      'reset_confirm': 'This deletes ALL cases, targets, categories and evidence.',
      'pdf_only_self': 'Only this target',
      'pdf_with_links': 'With connections',
      'menu': 'Menu',
      'home': 'Home',
      'snack_imported': 'Imported',
      'snack_exported': 'Exported',
      'snack_saved': 'Saved',
      'snack_deleted': 'Deleted',
      'no_name': '(no name)',
      'rename_category': 'Rename category',
      'rename_case': 'Rename case',
      'choose_target': 'Choose target',
      // Experimental features
      'experimental_features': 'Experimental Features',
      'experimental_subtitle': 'Manage experimental features',
      'exp_priority': 'Target priority (High / Medium / Low)',
      'exp_priority_desc': 'Adds a priority badge to each target card. Change priority directly from the target list.',
      'exp_global_map': 'Global case map with marker clustering',
      'exp_global_map_desc': 'All target coordinates on one screen.',
      'exp_export_graph_png': 'Export connections graph as PNG',
      'exp_export_graph_png_desc': 'Save or share the connections graph as an image.',
      'exp_case_tags': 'Case tags',
      'exp_case_tags_desc': 'Add and manage tags for the case itself.',
      'exp_case_pdf': 'Generate PDF of the entire case',
      'exp_case_pdf_desc': 'Export all targets in one PDF document.',
      'priority': 'Priority',
      'priority_high': 'High',
      'priority_medium': 'Medium',
      'priority_low': 'Low',
      'priority_none': 'None',
      'set_priority': 'Set priority',
      'global_case_map': 'Case Map',
      'no_coords_in_case': 'No coordinates found in this case.',
      'export_graph_png': 'Export graph (PNG)',
      'case_pdf': 'Case PDF',
      'generate_case_pdf': 'Generate Case PDF',
      'found_in': 'Found in',
      'edit_case_tags': 'Edit case tags',
      'case_tags_hint': 'tag1, tag2',
      'case_label': 'Case',
      'exp_export_map_png': 'Export map as PNG (save / share)',
      'exp_export_map_png_desc': 'Save or share the map with all markers as a PNG image. Works for a single target and for the entire case map.',
      'export_map_png': 'Export map (PNG)',
    },
    'ru': {
      'app_title': 'OSINT V',
      'cases': 'Дела',
      'new_case': 'Новое дело',
      'case_name': 'Название дела',
      'no_cases': 'Пока нет дел. Нажмите +, чтобы создать.',
      'targets': 'Цели',
      'new_target': 'Новая цель',
      'edit_target': 'Редактировать цель',
      'name': 'Имя',
      'surname': 'Фамилия',
      'patronymic': 'Отчество',
      'notes': 'Заметки',
      'tags': 'Теги',
      'add_tag': 'Добавить тег',
      'tag_name': 'Название тега',
      'deep_search': 'Глубокий поиск...',
      'no_targets': 'В этом деле пока нет целей. Нажмите +, чтобы добавить.',
      'no_results': 'Ничего не найдено.',
      'settings': 'Настройки',
      'theme': 'Тема',
      'light': 'Светлая',
      'dark': 'Тёмная',
      'amoled': 'AMOLED',
      'language': 'Язык',
      'storage_path': 'Путь хранилища',
      'export_json': 'Экспорт JSON',
      'import_json': 'Импорт JSON',
      'export_db': 'Выгрузить базу (SQLite .db)',
      'about': 'О приложении',
      'disclaimer':
          'Автор не несёт ответственности за использование данного приложения. '
              'Все данные хранятся локально на вашем устройстве. Используйте законно.',
      'tutorial': 'Руководство',
      'tutorial_text':
          '• Дела: на главном экране отображается список дел. Нажмите +, чтобы создать новое — достаточно ввести название. Внутри дела находится список целей.\n'
              '• Цели: нажмите + внутри дела, чтобы добавить цель. Откройте её — четыре вкладки: Инфо, Связи, Доказательства, Карта.\n'
              '• Приоритет цели: в редактировании цели можно задать приоритет (Высокий / Средний / Низкий). Также доступен быстрый выбор прямо из карточки цели в списке.\n'
              '• Категории и поля: во вкладке Инфо нажмите «+ Категорию». Внутри добавляйте пары ключ–значение. Зажмите и перетащите для сортировки.\n'
              '• Умное копирование: телефоны, номера карт (16 цифр) и координаты распознаются автоматически — появляется кнопка копирования. В настройках можно добавить свои символы-пометки.\n'
              '• Карта: если значение содержит координаты (например 50.45, 30.52), появится кнопка открытия на карте.\n'
              '• Связи: вкладка Связи → укажите другую цель из того же дела и причину. Нажмите на цель в списке связей, чтобы сразу перейти к ней.\n'
              '• Граф связей: кнопка в шапке дела — визуальная схема всех связей.\n'
              '• Поиск: строка поиска ищет по всем полям, категориям, тегам и заметкам с нечётким совпадением.',
      'custom_marks': 'Свои пометки',
      'custom_marks_subtitle': 'Управление пометками копирования',
      'no_marks_yet': 'Пометок пока нет.',
      'add_mark': 'Добавить пометку',
      'mark_char': 'Символ пометки',
      'mark_label': 'Подпись (необязательно)',
      'info': 'Инфо',
      'connections': 'Связи',
      'evidence': 'Доказательства',
      'map': 'Карта',
      'add_category': 'Добавить категорию',
      'category_name': 'Название категории',
      'add_kv': 'Добавить ключ-значение',
      'key': 'Ключ',
      'value': 'Значение',
      'add_connection': 'Добавить связь',
      'select_person': 'Выберите персону',
      'reasons': 'Причины (по одной в строке)',
      'add_evidence': 'Добавить доказательство',
      'pick_files': 'Выбрать файлы',
      'description': 'Описание',
      'generate_pdf': 'Сгенерировать PDF',
      'pdf_options': 'Параметры PDF',
      'include_connections': 'Включить связи',
      'include_evidence': 'Включить доказательства',
      'preview': 'Предпросмотр',
      'share': 'Поделиться',
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'delete': 'Удалить',
      'confirm_delete': 'Удалить элемент?',
      'this_action_cannot_be_undone': 'Это действие нельзя отменить.',
      'edit': 'Редактировать',
      'rename': 'Переименовать',
      'open': 'Открыть',
      'copy': 'Копировать',
      'copied': 'Скопировано',
      'open_on_map': 'Открыть на карте',
      'graph': 'Граф связей',
      'graph_filter': 'Фильтр по причине',
      'all_reasons': 'Все причины',
      'no_connections_yet': 'Связей пока нет.',
      'no_evidence_yet': 'Доказательств пока нет.',
      'no_categories_yet': 'Категорий пока нет.',
      'add': 'Добавить',
      'add_target': 'Добавить цель',
      'add_case': 'Добавить дело',
      'connections_count': 'связей',
      'targets_count': 'целей',
      'no_target_marker': 'В этой цели нет координат.',
      'storage_dir_info': 'Папка документов приложения',
      'reset_db': 'Сбросить базу',
      'reset_confirm': 'Это удалит ВСЕ дела, цели, категории и доказательства.',
      'pdf_only_self': 'Только эта цель',
      'pdf_with_links': 'Со связями',
      'menu': 'Меню',
      'home': 'Главная',
      'snack_imported': 'Импортировано',
      'snack_exported': 'Экспортировано',
      'snack_saved': 'Сохранено',
      'snack_deleted': 'Удалено',
      'no_name': '(без имени)',
      'rename_category': 'Переименовать категорию',
      'rename_case': 'Переименовать дело',
      'choose_target': 'Выберите цель',
      // Experimental features
      'experimental_features': 'Экспериментальные функции',
      'experimental_subtitle': 'Управление экспериментальными функциями',
      'exp_priority': 'Приоритет цели (Высокий / Средний / Низкий)',
      'exp_priority_desc': 'Добавляет метку приоритета на карточку цели. Менять приоритет можно прямо из списка целей.',
      'exp_global_map': 'Общая карта всего дела — маркеры всех целей с кластеризацией',
      'exp_global_map_desc': 'Все координаты целей на одном экране.',
      'exp_export_graph_png': 'Экспорт графа связей как изображения (PNG)',
      'exp_export_graph_png_desc': 'Сохранить или поделиться графом связей как картинкой.',
      'exp_case_tags': 'Добавление тега к делу',
      'exp_case_tags_desc': 'Добавлять и управлять тегами самого дела.',
      'exp_case_pdf': 'Генерация PDF всего дела',
      'exp_case_pdf_desc': 'Экспортировать все цели в один PDF-документ.',
      'priority': 'Приоритет',
      'priority_high': 'Высокий',
      'priority_medium': 'Средний',
      'priority_low': 'Низкий',
      'priority_none': '—',
      'set_priority': 'Приоритет цели',
      'global_case_map': 'Карта дела',
      'no_coords_in_case': 'В деле нет координат.',
      'export_graph_png': 'Экспорт графа (PNG)',
      'case_pdf': 'PDF дела',
      'generate_case_pdf': 'Сгенерировать PDF дела',
      'found_in': 'Найдено в',
      'edit_case_tags': 'Теги дела',
      'case_tags_hint': 'тег1, тег2',
      'case_label': 'Дело',
      'exp_export_map_png': 'Экспорт карты как PNG (сохранить / поделиться)',
      'exp_export_map_png_desc': 'Сохранить или поделиться картой с метками как PNG-изображением. Работает для одного человека и для всего дела.',
      'export_map_png': 'Экспорт карты (PNG)',
    },
  };

  static String t(String key) {
    final lang = AppState.instance.settings.language;
    return _t[lang]?[key] ?? _t['en']![key] ?? key;
  }
}

String tr(String key) => L10n.t(key);

// ============================================================================
// FUZZY SEARCH
// ============================================================================

class FuzzySearch {
  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    final d = List.generate(
      s.length + 1,
      (i) => List.generate(t.length + 1, (j) => 0),
    );
    for (int i = 0; i <= s.length; i++) d[i][0] = i;
    for (int j = 0; j <= t.length; j++) d[0][j] = j;
    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost,
        ].reduce(math.min);
      }
    }
    return d[s.length][t.length];
  }

  static bool matches(String query, String text) {
    final q = query.toLowerCase().trim();
    final t = text.toLowerCase();
    if (q.isEmpty) return true;
    if (t.contains(q)) return true;
    if (q.length < 3) return false;
    // Word-level fuzzy: each query word must match at least one text word
    final qWords = q.split(RegExp(r'\s+'));
    final tWords = t.split(RegExp(r'\W+'));
    for (final qw in qWords) {
      if (qw.length < 3) continue;
      final maxDist = qw.length <= 4 ? 1 : 2;
      bool wordFound = false;
      for (final tw in tWords) {
        if (tw.length < 2) continue;
        if (_levenshtein(qw, tw) <= maxDist) {
          wordFound = true;
          break;
        }
      }
      if (!wordFound) return false;
    }
    return qWords.any((w) => w.length >= 3);
  }
}

// ============================================================================
// SEARCH HIT — carries where the match was found and the matched snippet
// ============================================================================

class SearchHit {
  final String location; // e.g. "Категория → Контакты → телефон"
  final String snippet; // the matched text, possibly truncated
  const SearchHit({required this.location, required this.snippet});
}

List<SearchHit> findPersonHits(Person p, String query) {
  final q = query.toLowerCase().trim();
  if (q.isEmpty) return [];

  String _snip(String text) {
    final lower = text.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx >= 0) {
      final s = math.max(0, idx - 15);
      final e = math.min(text.length, idx + q.length + 30);
      return '${s > 0 ? "…" : ""}${text.substring(s, e)}${e < text.length ? "…" : ""}';
    }
    return text.length > 60 ? '${text.substring(0, 57)}…' : text;
  }

  // Name matches are already visible on the card — skip them as hit badges.
  if (FuzzySearch.matches(q, p.name) ||
      FuzzySearch.matches(q, p.surname) ||
      FuzzySearch.matches(q, p.patronymic)) {
    return [];
  }

  final hits = <SearchHit>[];

  // Tags (priority 1)
  for (final t in p.tags) {
    if (FuzzySearch.matches(q, t)) {
      hits.add(SearchHit(location: tr('tags'), snippet: t));
    }
  }

  // Categories & key-values (priority 2)
  for (final c in p.categories) {
    if (FuzzySearch.matches(q, c.name)) {
      hits.add(SearchHit(location: tr('connections'), snippet: c.name));
    }
    for (final kv in c.entries) {
      if (FuzzySearch.matches(q, kv.key)) {
        hits.add(SearchHit(location: c.name, snippet: kv.key));
      }
      if (kv.value.isNotEmpty && FuzzySearch.matches(q, kv.value)) {
        hits.add(SearchHit(
          location: '${c.name}${kv.key.isNotEmpty ? " → ${kv.key}" : ""}',
          snippet: _snip(kv.value),
        ));
      }
    }
  }

  // Notes (priority 3)
  if (p.notes.isNotEmpty && FuzzySearch.matches(q, p.notes)) {
    hits.add(SearchHit(location: tr('notes'), snippet: _snip(p.notes)));
  }

  // Evidence (priority 4)
  for (final ev in p.evidence) {
    if (ev.description.isNotEmpty && FuzzySearch.matches(q, ev.description)) {
      hits.add(SearchHit(location: tr('evidence'), snippet: _snip(ev.description)));
    }
  }

  // Connections (priority 5)
  for (final conn in p.connections) {
    for (final r in conn.reasons) {
      if (FuzzySearch.matches(q, r)) {
        hits.add(SearchHit(location: tr('connections'), snippet: r));
      }
    }
  }

  return hits;
}

// Keep old single-hit wrapper for backward compat
SearchHit? findPersonHit(Person p, String query) {
  final hits = findPersonHits(p, query);
  return hits.isEmpty ? null : hits.first;
}

bool personMatchesQuery(Person p, String query) {
  final q = query.toLowerCase().trim();
  if (q.isEmpty) return true;
  for (final s in p.searchHaystack()) {
    if (FuzzySearch.matches(q, s)) return true;
  }
  return false;
}

// ============================================================================
// MODELS
// ============================================================================

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

// ============================================================================
// APP STATE
// ============================================================================

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  late Directory docsDir;
  late File _dataFile;
  late SharedPreferences _prefs;

  Settings settings = Settings();
  List<CaseFile> cases = [];

  Future<void> init() async {
    docsDir = await getApplicationDocumentsDirectory();
    _dataFile = File('${docsDir.path}/osint_v_data.json');
    _prefs = await SharedPreferences.getInstance();

    final settingsJson = _prefs.getString('settings');
    if (settingsJson != null) {
      try {
        settings = Settings.fromJson(jsonDecode(settingsJson));
      } catch (_) {}
    }

    if (await _dataFile.exists()) {
      try {
        final raw = await _dataFile.readAsString();
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['cases'] is List) {
          cases = (data['cases'] as List)
              .map((e) => CaseFile.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (data['people'] is List) {
          final legacyPeople = (data['people'] as List)
              .map((e) => Person.fromJson(e as Map<String, dynamic>))
              .toList();
          if (legacyPeople.isNotEmpty) {
            cases = [
              CaseFile(name: 'Импорт / Imported', people: legacyPeople),
            ];
          }
        }
      } catch (_) {}
    }
  }

  Timer? _saveTimer;

  Future<void> persist() async {
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () async {
      final data = {'cases': cases.map((c) => c.toJson()).toList()};
      await _dataFile.writeAsString(jsonEncode(data));
      await _prefs.setString('settings', jsonEncode(settings.toJson()));
    });
  }

  Future<void> persistSettingsOnly() async {
    await _prefs.setString('settings', jsonEncode(settings.toJson()));
    notifyListeners();
  }

  String get dataFilePath => _dataFile.path;

  CaseFile? findCase(String caseId) {
    for (final c in cases) {
      if (c.id == caseId) return c;
    }
    return null;
  }

  Future<File> exportJsonFile() async {
    final f = File('${docsDir.path}/osint_v_export.json');
    final data = {'cases': cases.map((c) => c.toJson()).toList()};
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return f;
  }

  Future<void> importJsonFromFile(File f) async {
    final raw = await f.readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final byId = {for (final c in cases) c.id: c};
    if (data['cases'] is List) {
      final imported = (data['cases'] as List)
          .map((e) => CaseFile.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final c in imported) {
        byId[c.id] = c;
      }
    } else if (data['people'] is List) {
      final legacyPeople = (data['people'] as List)
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
      if (legacyPeople.isNotEmpty) {
        final c = CaseFile(name: 'Импорт / Imported', people: legacyPeople);
        byId[c.id] = c;
      }
    }
    cases = byId.values.toList();
    await persist();
  }

  Future<void> resetDatabase() async {
    cases = [];
    await persist();
  }

  Future<File> exportRawDb() async {
    final outPath = '${docsDir.path}/osint_v_db.db';
    final outFile = File(outPath);
    if (await outFile.exists()) {
      try {
        await outFile.delete();
      } catch (_) {}
    }

    final db = await openDatabase(outPath, version: 1);
    try {
      final batch = db.batch();
      batch.execute('''
        CREATE TABLE cases (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL
        )
      ''');
      batch.execute('''
        CREATE TABLE people (
          id TEXT PRIMARY KEY,
          case_id TEXT NOT NULL,
          name TEXT NOT NULL,
          surname TEXT NOT NULL,
          patronymic TEXT NOT NULL,
          notes TEXT NOT NULL
        )
      ''');
      batch.execute('''
        CREATE TABLE person_tags (
          person_id TEXT NOT NULL,
          tag TEXT NOT NULL,
          PRIMARY KEY (person_id, tag)
        )
      ''');
      batch.execute('''
        CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          person_id TEXT NOT NULL,
          ord INTEGER NOT NULL,
          name TEXT NOT NULL
        )
      ''');
      batch.execute('''
        CREATE TABLE kvs (
          id TEXT PRIMARY KEY,
          category_id TEXT NOT NULL,
          ord INTEGER NOT NULL,
          key TEXT NOT NULL,
          value TEXT NOT NULL
        )
      ''');
      batch.execute('''
        CREATE TABLE connections (
          id TEXT PRIMARY KEY,
          from_person_id TEXT NOT NULL,
          to_person_id TEXT NOT NULL
        )
      ''');
      batch.execute('''
        CREATE TABLE connection_reasons (
          connection_id TEXT NOT NULL,
          ord INTEGER NOT NULL,
          reason TEXT NOT NULL,
          PRIMARY KEY (connection_id, ord)
        )
      ''');
      batch.execute('''
        CREATE TABLE evidence (
          id TEXT PRIMARY KEY,
          person_id TEXT NOT NULL,
          description TEXT NOT NULL
        )
      ''');
      batch.execute('''
        CREATE TABLE evidence_files (
          evidence_id TEXT NOT NULL,
          ord INTEGER NOT NULL,
          path TEXT NOT NULL,
          PRIMARY KEY (evidence_id, ord)
        )
      ''');
      await batch.commit(noResult: true);

      final write = db.batch();
      for (final cs in cases) {
        write.insert('cases', {'id': cs.id, 'name': cs.name});
        for (final p in cs.people) {
          write.insert('people', {
            'id': p.id,
            'case_id': cs.id,
            'name': p.name,
            'surname': p.surname,
            'patronymic': p.patronymic,
            'notes': p.notes,
          });
          for (final t in p.tags) {
            write.insert(
              'person_tags',
              {'person_id': p.id, 'tag': t},
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
          for (var ci = 0; ci < p.categories.length; ci++) {
            final c = p.categories[ci];
            write.insert('categories', {
              'id': c.id,
              'person_id': p.id,
              'ord': ci,
              'name': c.name,
            });
            for (var ki = 0; ki < c.entries.length; ki++) {
              final kv = c.entries[ki];
              write.insert('kvs', {
                'id': kv.id,
                'category_id': c.id,
                'ord': ki,
                'key': kv.key,
                'value': kv.value,
              });
            }
          }
          for (final link in p.connections) {
            write.insert('connections', {
              'id': link.id,
              'from_person_id': p.id,
              'to_person_id': link.targetPersonId,
            });
            for (var ri = 0; ri < link.reasons.length; ri++) {
              write.insert('connection_reasons', {
                'connection_id': link.id,
                'ord': ri,
                'reason': link.reasons[ri],
              });
            }
          }
          for (final ev in p.evidence) {
            write.insert('evidence', {
              'id': ev.id,
              'person_id': p.id,
              'description': ev.description,
            });
            for (var fi = 0; fi < ev.filePaths.length; fi++) {
              write.insert('evidence_files', {
                'evidence_id': ev.id,
                'ord': fi,
                'path': ev.filePaths[fi],
              });
            }
          }
        }
      }
      await write.commit(noResult: true);
    } finally {
      await db.close();
    }
    return outFile;
  }
}

// ============================================================================
// PARSERS / DETECTION
// ============================================================================

class ValueDetector {
  static final RegExp coordRe = RegExp(
    r'(-?\d{1,3}(?:\.\d+)?)\s*,\s*(-?\d{1,3}(?:\.\d+)?)',
  );
  static final RegExp phoneRe = RegExp(
    r'(\+\d[\d\s\-\(\)]{6,}\d)',
  );
  static final RegExp cardRe = RegExp(
    r'(?:\d{4}[\s-]?){3,4}\d{1,4}',
  );

  static LatLng? extractCoord(String value) {
    final m = coordRe.firstMatch(value.trim());
    if (m == null) return null;
    final lat = double.tryParse(m.group(1)!);
    final lng = double.tryParse(m.group(2)!);
    if (lat == null || lng == null) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return LatLng(lat, lng);
  }

  static String? extractPhone(String value) {
    final m = phoneRe.firstMatch(value);
    return m?.group(1);
  }

  static String? extractCard(String value) {
    final m = cardRe.firstMatch(value);
    if (m == null) return null;
    final digits = m.group(0)!.replaceAll(RegExp(r'\s|-'), '');
    if (digits.length < 13 || digits.length > 19) return null;
    return digits;
  }

  static String? matchedCustomMark(String value) {
    final marks = AppState.instance.settings.marks;
    final v = value.trimLeft();
    for (final m in marks) {
      if (m.char.isNotEmpty && v.startsWith(m.char)) return m.char;
    }
    return null;
  }
}

// ============================================================================
// THEME
// ============================================================================

ThemeData buildTheme(AppTheme t) {
  const seed = Color(0xFF6750A4);
  switch (t) {
    case AppTheme.light:
      return ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: seed, brightness: Brightness.light),
      );
    case AppTheme.dark:
      return ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: seed, brightness: Brightness.dark),
      );
    case AppTheme.amoled:
      final base = ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: seed, brightness: Brightness.dark),
      );
      return base.copyWith(
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        cardTheme: CardThemeData(
          color: const Color(0xFF0A0A0A),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF1F1F1F)),
          ),
        ),
        dialogTheme:
            const DialogThemeData(backgroundColor: Color(0xFF0A0A0A)),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF0A0A0A),
        ),
      );
  }
}

// ============================================================================
// APP ROOT
// ============================================================================

class OsintApp extends StatelessWidget {
  const OsintApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'OSINT V',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(AppState.instance.settings.theme),
          home: const HomeScreen(),
        );
      },
    );
  }
}

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
      // Check case tags
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
      // Search through people
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
                    // Search hit — show person name + where it was found
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

// ============================================================================
// CASE SCREEN — list of targets in a case
// ============================================================================

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
    if (q.isEmpty) return c.people.map((p) => _PersonMatch(p, const [])).toList();
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
            title: Text(c.name.isEmpty ? '—' : c.name),
            actions: [
              if (exp.globalMap)
                IconButton(
                  tooltip: tr('global_case_map'),
                  icon: const Icon(Icons.map_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => GlobalMapScreen(caseId: c.id)),
                  ),
                ),
              if (exp.casePdf)
                IconButton(
                  tooltip: tr('case_pdf'),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: () => _openCasePdf(context, c),
                ),
              IconButton(
                tooltip: tr('graph'),
                icon: const Icon(Icons.hub_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => GraphScreen(caseId: c.id)),
                ),
              ),
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
                                ? tr('no_targets')
                                : tr('no_results'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 96),
                        itemCount: list.length,
                        itemBuilder: (context, i) => _PersonCard(
                          caseId: c.id,
                          person: list[i].person,
                          hits: list[i].hits,
                          query: _query.trim().isEmpty ? null : _query.trim(),
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddPersonDialog(context, c),
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(tr('new_target')),
          ),
        );
      },
    );
  }

  Future<void> _openCasePdf(BuildContext context, CaseFile c) async {
    bool withConnections = false;
    bool withEvidence = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: Text(tr('generate_case_pdf')),
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
      final bytes = await CasePdfBuilder.buildCasePdf(
        c,
        withConnections: withConnections,
        withEvidence: withEvidence,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CasePdfPreviewScreen(bytes: bytes, caseFile: c),
        ),
      );
    }
  }

  Future<void> _showAddPersonDialog(BuildContext context, CaseFile c) async {
    final nameC = TextEditingController();
    final surC = TextEditingController();
    final patC = TextEditingController();
    final tagsC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('new_target')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameC,
                  autofocus: true,
                  decoration: InputDecoration(labelText: tr('name'))),
              TextField(
                  controller: surC,
                  decoration: InputDecoration(labelText: tr('surname'))),
              TextField(
                  controller: patC,
                  decoration: InputDecoration(labelText: tr('patronymic'))),
              const SizedBox(height: 8),
              TextField(
                controller: tagsC,
                decoration: InputDecoration(
                  labelText: tr('tags'),
                  hintText: 'tag1, tag2',
                ),
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
              child: Text(tr('add'))),
        ],
      ),
    );
    if (ok == true) {
      final p = Person(
        name: nameC.text.trim(),
        surname: surC.text.trim(),
        patronymic: patC.text.trim(),
        tags: tagsC.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
      c.people.add(p);
      await AppState.instance.persist();
    }
  }
}

class _PersonCard extends StatefulWidget {
  final String caseId;
  final Person person;
  final List<SearchHit> hits;
  final String? query;
  const _PersonCard({
    required this.caseId,
    required this.person,
    this.hits = const [],
    this.query,
  });

  @override
  State<_PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends State<_PersonCard> {
  Future<void> _quickSetPriority(BuildContext context) async {
    // Use a wrapper to distinguish "dismissed" from "chose None"
    const _noneKey = 'none';
    final result = await showModalBottomSheet<Object>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                tr('set_priority'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.grey),
              title: Text(tr('priority_none')),
              onTap: () => Navigator.pop(ctx, _noneKey),
              trailing: widget.person.priority == null
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
            ),
            ...Priority.values.map((p) => ListTile(
              leading: Icon(Icons.circle, size: 14, color: p.color),
              title: Text(p.label),
              onTap: () => Navigator.pop(ctx, p),
              trailing: widget.person.priority == p
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (result == null) return; // dismissed
    final newPriority = result == _noneKey ? null : result as Priority;
    widget.person.priority = newPriority;
    await AppState.instance.persist();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exp = AppState.instance.settings.experimental;
    final person = widget.person;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PersonScreen(caseId: widget.caseId, personId: person.id),
          ),
        ),
        onLongPress: () async {
          final ok = await showDeleteDialog(context);
          if (ok == true) {
            final c = AppState.instance.findCase(widget.caseId);
            if (c == null) return;
            c.people.removeWhere((p) => p.id == person.id);
            for (final p in c.people) {
              p.connections.removeWhere(
                  (link) => link.targetPersonId == person.id);
            }
            await AppState.instance.persist();
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
                    // Priority row ABOVE the name (only when feature enabled)
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
                                  color: Colors.grey.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.25)),
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
                                fontSize: 16, fontWeight: FontWeight.w600),
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
                    // Search hit badge — show up to 2 hits
                    if (widget.hits.isNotEmpty && widget.query != null && widget.query!.isNotEmpty) ...[
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
                            for (final hit in widget.hits.take(2)) ...[
                              Text(
                                '${tr("found_in")}: ${hit.location}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              _HighlightText(
                                  text: hit.snippet, query: widget.query!),
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

// ============================================================================
// PERSON SCREEN (Tabs: Info / Connections / Evidence / Map)
// ============================================================================

class PersonScreen extends StatefulWidget {
  final String caseId;
  final String personId;
  const PersonScreen(
      {super.key, required this.caseId, required this.personId});
  @override
  State<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends State<PersonScreen> {
  CaseFile? get _case => AppState.instance.findCase(widget.caseId);
  Person? get _person => _case?.findPerson(widget.personId);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final c = _case;
        final p = _person;
        if (c == null || p == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(p.fullName),
              actions: [
                IconButton(
                  tooltip: tr('edit'),
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _editBasics,
                ),
                IconButton(
                  tooltip: tr('generate_pdf'),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: _openPdfFlow,
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'delete') {
                      final ok = await showDeleteDialog(context);
                      if (ok == true) {
                        c.people.removeWhere(
                            (pp) => pp.id == widget.personId);
                        for (final pp in c.people) {
                          pp.connections.removeWhere((link) =>
                              link.targetPersonId == widget.personId);
                        }
                        await AppState.instance.persist();
                        if (!mounted) return;
                        Navigator.pop(context);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'delete', child: Text(tr('delete'))),
                  ],
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: tr('info')),
                  Tab(text: tr('connections')),
                  Tab(text: tr('evidence')),
                  Tab(text: tr('map')),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _InfoTab(person: p, onChange: _persist),
                _ConnectionsTab(
                    caseFile: c, person: p, onChange: _persist),
                _EvidenceTab(person: p, onChange: _persist),
                _MapTab(person: p),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _persist() => AppState.instance.persist();

  Future<void> _editBasics() async {
    final p = _person;
    if (p == null) return;
    final nameC = TextEditingController(text: p.name);
    final surC = TextEditingController(text: p.surname);
    final patC = TextEditingController(text: p.patronymic);
    final notesC = TextEditingController(text: p.notes);
    final tagsC = TextEditingController(text: p.tags.join(', '));
    final exp = AppState.instance.settings.experimental;
    Priority? selectedPriority = p.priority;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: Text(tr('edit_target')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameC,
                    autofocus: true,
                    decoration: InputDecoration(labelText: tr('name'))),
                TextField(
                    controller: surC,
                    decoration: InputDecoration(labelText: tr('surname'))),
                TextField(
                    controller: patC,
                    decoration:
                        InputDecoration(labelText: tr('patronymic'))),
                TextField(
                  controller: notesC,
                  decoration: InputDecoration(labelText: tr('notes')),
                  maxLines: 3,
                ),
                TextField(
                  controller: tagsC,
                  decoration: InputDecoration(
                    labelText: tr('tags'),
                    hintText: 'tag1, tag2',
                  ),
                ),
                if (exp.priority) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Priority?>(
                    value: selectedPriority,
                    decoration: InputDecoration(labelText: tr('priority')),
                    items: [
                      DropdownMenuItem<Priority?>(
                        value: null,
                        child: Text(tr('priority_none')),
                      ),
                      ...Priority.values.map(
                        (prio) => DropdownMenuItem<Priority?>(
                          value: prio,
                          child: Row(
                            children: [
                              Icon(Icons.circle,
                                  size: 10, color: prio.color),
                              const SizedBox(width: 8),
                              Text(prio.label),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setS(() => selectedPriority = v),
                  ),
                ],
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
        );
      }),
    );
    if (ok == true) {
      p.name = nameC.text.trim();
      p.surname = surC.text.trim();
      p.patronymic = patC.text.trim();
      p.notes = notesC.text.trim();
      p.tags = tagsC.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (exp.priority) p.priority = selectedPriority;
      await _persist();
    }
  }

  Future<void> _openPdfFlow() async {
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
      final p = _person;
      final c = _case;
      if (p == null || c == null) return;
      final bytes = await PdfBuilder.buildPersonPdf(
        p,
        caseFile: c,
        withConnections: withConnections,
        withEvidence: withEvidence,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            bytes: bytes,
            person: p,
            withEvidence: withEvidence,
          ),
        ),
      );
    }
  }
}

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
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      children: [
        if (p.notes.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(p.notes),
            ),
          ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (oldIdx, newIdx) async {
            setState(() {
              if (newIdx > oldIdx) newIdx -= 1;
              final c = p.categories.removeAt(oldIdx);
              p.categories.insert(newIdx, c);
            });
            await widget.onChange();
          },
          itemCount: p.categories.length,
          itemBuilder: (ctx, i) {
            final c = p.categories[i];
            return _CategoryCard(
              key: ValueKey(c.id),
              index: i,
              category: c,
              onChange: () async {
                setState(() {});
                await widget.onChange();
              },
              onDelete: () async {
                final ok = await showDeleteDialog(context);
                if (ok == true) {
                  setState(() => p.categories.removeAt(i));
                  await widget.onChange();
                }
              },
            );
          },
        ),
        if (p.categories.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(tr('no_categories_yet'),
                  style: const TextStyle(color: Colors.grey)),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: _addCategory,
          icon: const Icon(Icons.add),
          label: Text(tr('add_category')),
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
      setState(() => widget.person.categories
          .add(CategoryBlock(name: c.text.trim())));
      await widget.onChange();
    }
  }
}

class _CategoryCard extends StatefulWidget {
  final int index;
  final CategoryBlock category;
  final Future<void> Function() onChange;
  final Future<void> Function() onDelete;
  const _CategoryCard({
    super.key,
    required this.index,
    required this.category,
    required this.onChange,
    required this.onDelete,
  });
  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: widget.index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.drag_indicator, color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: Text(
                    c.name.isEmpty ? '—' : c.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: _renameCategory,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (oldIdx, newIdx) async {
              setState(() {
                if (newIdx > oldIdx) newIdx -= 1;
                final kv = c.entries.removeAt(oldIdx);
                c.entries.insert(newIdx, kv);
              });
              await widget.onChange();
            },
            itemCount: c.entries.length,
            itemBuilder: (ctx, i) {
              final kv = c.entries[i];
              return _KvTile(
                key: ValueKey(kv.id),
                index: i,
                kv: kv,
                onEdit: () => _editKv(kv),
                onDelete: () async {
                  final ok = await showDeleteDialog(context);
                  if (ok == true) {
                    setState(() => c.entries.removeAt(i));
                    await widget.onChange();
                  }
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: TextButton.icon(
              onPressed: _addKv,
              icon: const Icon(Icons.add, size: 18),
              label: Text(tr('add_kv')),
            ),
          ),
        ],
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

// ============================================================================
// CONNECTIONS TAB (within a single case)
// ============================================================================

class _ConnectionsTab extends StatefulWidget {
  final CaseFile caseFile;
  final Person person;
  final Future<void> Function() onChange;
  const _ConnectionsTab(
      {required this.caseFile,
      required this.person,
      required this.onChange});
  @override
  State<_ConnectionsTab> createState() => _ConnectionsTabState();
}

class _ConnectionsTabState extends State<_ConnectionsTab> {
  @override
  Widget build(BuildContext context) {
    final p = widget.person;
    return Stack(
      children: [
        if (p.connections.isEmpty)
          Center(
            child: Text(tr('no_connections_yet'),
                style: const TextStyle(color: Colors.grey)),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: p.connections.length,
            itemBuilder: (ctx, i) {
              final link = p.connections[i];
              final other = widget.caseFile.findPerson(link.targetPersonId);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(other?.initials ?? '?',
                        textAlign: TextAlign.center),
                  ),
                  title: Text(other?.fullName ?? '???'),
                  subtitle: link.reasons.isEmpty
                      ? Text(tr('reasons'))
                      : Text(link.reasons.join('\n')),
                  isThreeLine: link.reasons.length > 1,
                  onTap: () {
                    if (other != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PersonScreen(
                              caseId: widget.caseFile.id,
                              personId: other.id),
                        ),
                      );
                    }
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        await _editLink(link);
                      } else if (v == 'delete') {
                        final ok = await showDeleteDialog(context);
                        if (ok == true) {
                          setState(() => p.connections.removeAt(i));
                          await widget.onChange();
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text(tr('edit'))),
                      PopupMenuItem(value: 'delete', child: Text(tr('delete'))),
                    ],
                  ),
                ),
              );
            },
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'connFab',
            onPressed: _addConnection,
            icon: const Icon(Icons.link),
            label: Text(tr('add_connection')),
          ),
        ),
      ],
    );
  }

  Future<void> _addConnection() async {
    final all = widget.caseFile.people
        .where((p) => p.id != widget.person.id)
        .toList();
    if (all.isEmpty) return;
    final picked = await showDialog<Person>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr('select_person')),
        children: [
          for (final p in all)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, p),
              child: Text(p.fullName),
            ),
        ],
      ),
    );
    if (picked == null) return;
    final link = ConnectionLink(targetPersonId: picked.id);
    final ok = await _editLinkDialog(link, picked);
    if (ok) {
      setState(() => widget.person.connections.add(link));
      final alreadyLinked = picked.connections
          .any((c) => c.targetPersonId == widget.person.id);
      if (!alreadyLinked) {
        picked.connections.add(ConnectionLink(
          targetPersonId: widget.person.id,
          reasons: List.of(link.reasons),
        ));
      }
      await widget.onChange();
    }
  }

  Future<void> _editLink(ConnectionLink link) async {
    final other = widget.caseFile.findPerson(link.targetPersonId);
    if (other == null) return;
    final ok = await _editLinkDialog(link, other);
    if (ok) {
      setState(() {});
      await widget.onChange();
    }
  }

  Future<bool> _editLinkDialog(ConnectionLink link, Person other) async {
    final c = TextEditingController(text: link.reasons.join('\n'));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(other.fullName),
        content: TextField(
          controller: c,
          maxLines: 5,
          decoration: InputDecoration(labelText: tr('reasons')),
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
      link.reasons = c.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      return true;
    }
    return false;
  }
}

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
    final p = widget.person;
    return Stack(
      children: [
        if (p.evidence.isEmpty)
          Center(
            child: Text(tr('no_evidence_yet'),
                style: const TextStyle(color: Colors.grey)),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: p.evidence.length,
            itemBuilder: (ctx, i) {
              final ev = p.evidence[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ev.description.isEmpty ? '—' : ev.description,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _editEvidence(ev)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              final ok = await showDeleteDialog(context);
                              if (ok == true) {
                                setState(() => p.evidence.removeAt(i));
                                await widget.onChange();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final fp in ev.filePaths) _FileTile(path: fp),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'evidFab',
            onPressed: _addEvidence,
            icon: const Icon(Icons.add),
            label: Text(tr('add_evidence')),
          ),
        ),
      ],
    );
  }

  Future<void> _addEvidence() async {
    final ev = EvidenceItem();
    final ok = await _evidenceDialog(ev);
    if (ok) {
      setState(() => widget.person.evidence.add(ev));
      await widget.onChange();
    }
  }

  Future<void> _editEvidence(EvidenceItem ev) async {
    final ok = await _evidenceDialog(ev);
    if (ok) {
      setState(() {});
      await widget.onChange();
    }
  }

  Future<bool> _evidenceDialog(EvidenceItem ev) async {
    final descC = TextEditingController(text: ev.description);
    List<String> picked = List.of(ev.filePaths);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: Text(tr('add_evidence')),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: descC,
                    decoration: InputDecoration(labelText: tr('description')),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in picked)
                        InputChip(
                          label: Text(p.split('/').last,
                              overflow: TextOverflow.ellipsis),
                          onDeleted: () => setS(() => picked.remove(p)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: Text(tr('pick_files')),
                    onPressed: () async {
                      final res = await FilePicker.platform.pickFiles(
                          allowMultiple: true, withData: false);
                      if (res != null) {
                        for (final f in res.files) {
                          if (f.path == null) continue;
                          final dest = await _copyToAppDocs(File(f.path!));
                          setS(() => picked.add(dest.path));
                        }
                      }
                    },
                  ),
                ],
              ),
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
        );
      }),
    );
    if (ok == true) {
      ev.description = descC.text;
      ev.filePaths = picked;
      return true;
    }
    return false;
  }
}

Future<File> _copyToAppDocs(File src) async {
  final docs = AppState.instance.docsDir;
  final evDir = Directory('${docs.path}/evidence');
  if (!await evDir.exists()) await evDir.create(recursive: true);
  final base = src.path.split('/').last;
  final dest =
      File('${evDir.path}/${DateTime.now().millisecondsSinceEpoch}_$base');
  return src.copy(dest.path);
}

bool _isImagePath(String path) {
  final p = path.toLowerCase();
  return p.endsWith('.jpg') ||
      p.endsWith('.jpeg') ||
      p.endsWith('.png') ||
      p.endsWith('.webp') ||
      p.endsWith('.gif') ||
      p.endsWith('.bmp');
}

class _FileTile extends StatelessWidget {
  final String path;
  const _FileTile({required this.path});
  @override
  Widget build(BuildContext context) {
    final isImg = _isImagePath(path);
    return InkWell(
      onTap: () => OpenFilex.open(path),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.hardEdge,
        child: isImg
            ? Image.file(File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fileIcon())
            : _fileIcon(name: path.split('/').last),
      ),
    );
  }

  Widget _fileIcon({String? name}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 36),
          const SizedBox(height: 6),
          if (name != null)
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// MAP TAB (per-person, all coordinates from kv values)
// ============================================================================

class _MapTab extends StatefulWidget {
  final Person person;
  const _MapTab({required this.person});
  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> {
  final _mapController = MapController();
  final _repaintKey = GlobalKey();

  List<({LatLng pt, String label})> _collect() {
    final out = <({LatLng pt, String label})>[];
    for (final c in widget.person.categories) {
      for (final kv in c.entries) {
        final pt = ValueDetector.extractCoord(kv.value);
        if (pt != null) {
          final label = kv.key.isEmpty ? c.name : kv.key;
          out.add((pt: pt, label: label));
        }
      }
    }
    return out;
  }

  void _fitMarkers(List<({LatLng pt, String label})> markers) {
    if (markers.isEmpty) return;
    if (markers.length == 1) {
      _mapController.move(markers.first.pt, 14);
      return;
    }
    double minLat = markers.first.pt.latitude;
    double maxLat = markers.first.pt.latitude;
    double minLng = markers.first.pt.longitude;
    double maxLng = markers.first.pt.longitude;
    for (final m in markers) {
      if (m.pt.latitude < minLat) minLat = m.pt.latitude;
      if (m.pt.latitude > maxLat) maxLat = m.pt.latitude;
      if (m.pt.longitude < minLng) minLng = m.pt.longitude;
      if (m.pt.longitude > maxLng) maxLng = m.pt.longitude;
    }
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    _mapController.move(center, 11);
  }

  Future<void> _exportPng(List<({LatLng pt, String label})> markers) async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final f = File(
          '${AppState.instance.docsDir.path}/map_${DateTime.now().millisecondsSinceEpoch}.png');
      await f.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(f.path)], text: 'OSINT V Map');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = _collect();
    final exp = AppState.instance.settings.experimental;
    if (markers.isEmpty) {
      return Center(
        child: Text(tr('no_target_marker'),
            style: const TextStyle(color: Colors.grey)),
      );
    }
    return Stack(
      children: [
        RepaintBoundary(
          key: _repaintKey,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: markers.first.pt,
              initialZoom: markers.length == 1 ? 14 : 10,
              onMapReady: () => _fitMarkers(markers),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'osint_v',
              ),
              MarkerLayer(
                markers: [
                  for (final m in markers)
                    Marker(
                      point: m.pt,
                      width: 160,
                      height: 60,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.red, size: 36),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(m.label,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (exp.exportMapPng)
          Positioned(
            right: 12,
            bottom: 12,
            child: FloatingActionButton.small(
              heroTag: 'mapTabPngFab',
              tooltip: tr('export_map_png'),
              onPressed: () => _exportPng(markers),
              child: const Icon(Icons.image_outlined),
            ),
          ),
      ],
    );
  }
}

class SingleMarkerMapScreen extends StatelessWidget {
  final LatLng point;
  final String label;
  const SingleMarkerMapScreen(
      {super.key, required this.point, required this.label});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(label),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(
                  text: '${point.latitude}, ${point.longitude}'));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('copied'))),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () async {
              final url = Uri.parse(
                  'https://www.openstreetmap.org/?mlat=${point.latitude}&mlon=${point.longitude}#map=15/${point.latitude}/${point.longitude}');
              await launchUrl(url, mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(initialCenter: point, initialZoom: 14),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'osint_v',
          ),
          MarkerLayer(markers: [
            Marker(
              point: point,
              width: 60,
              height: 60,
              child: const Icon(Icons.location_on,
                  color: Colors.red, size: 48),
            ),
          ]),
        ],
      ),
    );
  }
}

// ============================================================================
// GLOBAL MAP SCREEN — all targets' coordinates in a case
// ============================================================================

class GlobalMapScreen extends StatefulWidget {
  final String caseId;
  const GlobalMapScreen({super.key, required this.caseId});
  @override
  State<GlobalMapScreen> createState() => _GlobalMapScreenState();
}

class _GlobalMapScreenState extends State<GlobalMapScreen> {
  final _mapController = MapController();
  final _repaintKey = GlobalKey();

  List<({LatLng pt, String label, String personName})> _collectAll() {
    final c = AppState.instance.findCase(widget.caseId);
    if (c == null) return [];
    final out = <({LatLng pt, String label, String personName})>[];
    for (final person in c.people) {
      for (final cat in person.categories) {
        for (final kv in cat.entries) {
          final pt = ValueDetector.extractCoord(kv.value);
          if (pt != null) {
            final label = kv.key.isEmpty ? cat.name : kv.key;
            out.add((
              pt: pt,
              label: label,
              personName: person.fullName,
            ));
          }
        }
      }
    }
    return out;
  }

  void _fitAll(List<({LatLng pt, String label, String personName})> markers) {
    if (markers.isEmpty) return;
    if (markers.length == 1) {
      _mapController.move(markers.first.pt, 13);
      return;
    }
    double minLat = markers.first.pt.latitude;
    double maxLat = markers.first.pt.latitude;
    double minLng = markers.first.pt.longitude;
    double maxLng = markers.first.pt.longitude;
    for (final m in markers) {
      if (m.pt.latitude < minLat) minLat = m.pt.latitude;
      if (m.pt.latitude > maxLat) maxLat = m.pt.latitude;
      if (m.pt.longitude < minLng) minLng = m.pt.longitude;
      if (m.pt.longitude > maxLng) maxLng = m.pt.longitude;
    }
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    _mapController.move(center, 9);
  }

  Future<void> _exportPng() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final f = File(
          '${AppState.instance.docsDir.path}/case_map_${DateTime.now().millisecondsSinceEpoch}.png');
      await f.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(f.path)], text: 'OSINT V Case Map');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppState.instance.findCase(widget.caseId);
    final markers = _collectAll();
    final exp = AppState.instance.settings.experimental;
    return Scaffold(
      appBar: AppBar(
        title: Text('${tr("global_case_map")} — ${c?.name ?? ""}'),
        actions: [
          if (exp.exportMapPng && markers.isNotEmpty)
            IconButton(
              tooltip: tr('export_map_png'),
              icon: const Icon(Icons.image_outlined),
              onPressed: _exportPng,
            ),
        ],
      ),
      body: markers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  tr('no_coords_in_case'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          : RepaintBoundary(
              key: _repaintKey,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: markers.first.pt,
                  initialZoom: markers.length == 1 ? 13 : 7,
                  onMapReady: () => _fitAll(markers),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'osint_v',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final m in markers)
                        Marker(
                          point: m.pt,
                          width: 180,
                          height: 70,
                          alignment: Alignment.topCenter,
                          child: _GlobalMarker(
                            label: m.label,
                            personName: m.personName,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _GlobalMarker extends StatelessWidget {
  final String label;
  final String personName;
  const _GlobalMarker({required this.label, required this.personName});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.location_on, color: Colors.deepOrange, size: 34),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                personName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SETTINGS SCREEN
// ============================================================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final s = AppState.instance.settings;
    return Scaffold(
      appBar: AppBar(title: Text(tr('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _section(tr('theme')),
          SegmentedButton<AppTheme>(
            segments: [
              ButtonSegment(value: AppTheme.light, label: Text(tr('light'))),
              ButtonSegment(value: AppTheme.dark, label: Text(tr('dark'))),
              ButtonSegment(value: AppTheme.amoled, label: Text(tr('amoled'))),
            ],
            selected: {s.theme},
            onSelectionChanged: (set) async {
              s.theme = set.first;
              await AppState.instance.persistSettingsOnly();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          _section(tr('language')),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'en', label: Text('EN')),
              ButtonSegment(value: 'ru', label: Text('RU')),
            ],
            selected: {s.language},
            onSelectionChanged: (set) async {
              s.language = set.first;
              await AppState.instance.persistSettingsOnly();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          _section(tr('storage_path')),
          Card(
            child: ListTile(
              title: Text(tr('storage_dir_info')),
              subtitle: Text(AppState.instance.dataFilePath),
              isThreeLine: true,
              leading: const Icon(Icons.folder_outlined),
            ),
          ),
          const SizedBox(height: 16),
          _section('JSON / DB'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: Text(tr('export_json')),
                  onTap: _exportJson,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(tr('import_json')),
                  onTap: _importJson,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: Text(tr('export_db')),
                  onTap: _exportRawDb,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(tr('reset_db'),
                      style: const TextStyle(color: Colors.red)),
                  onTap: _resetDb,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(tr('custom_marks')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.label_outline),
              title: Text(tr('custom_marks')),
              subtitle: Text(
                s.marks.isEmpty
                    ? tr('custom_marks_subtitle')
                    : '${s.marks.length} • ${tr('custom_marks_subtitle')}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MarksScreen()),
                );
                if (mounted) setState(() {});
              },
            ),
          ),
          const SizedBox(height: 16),
          // Experimental features button
          _section(tr('experimental_features')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.science_outlined),
              title: Text(tr('experimental_features')),
              subtitle: Text(tr('experimental_subtitle')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ExperimentalFeaturesScreen()),
                );
                if (mounted) setState(() {});
              },
            ),
          ),
          const SizedBox(height: 16),
          _section(tr('tutorial')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(tr('tutorial_text'),
                  style: const TextStyle(height: 1.4)),
            ),
          ),
          const SizedBox(height: 16),
          _section(tr('about')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(tr('disclaimer')),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
        child: Text(title,
            style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w600)),
      );

  Future<void> _exportJson() async {
    final f = await AppState.instance.exportJsonFile();
    await Share.shareXFiles([XFile(f.path)], text: 'OSINT V data');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('snack_exported'))),
      );
    }
  }

  Future<void> _exportRawDb() async {
    final f = await AppState.instance.exportRawDb();
    await Share.shareXFiles([XFile(f.path)], text: 'OSINT V raw DB');
  }

  Future<void> _importJson() async {
    final res = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json']);
    if (res == null || res.files.single.path == null) return;
    await AppState.instance.importJsonFromFile(File(res.files.single.path!));
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('snack_imported'))),
      );
    }
  }

  Future<void> _resetDb() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('reset_db')),
        content: Text(tr('reset_confirm')),
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
    if (ok == true) {
      await AppState.instance.resetDatabase();
      if (mounted) setState(() {});
    }
  }
}

// ============================================================================
// EXPERIMENTAL FEATURES SCREEN
// ============================================================================

class ExperimentalFeaturesScreen extends StatefulWidget {
  const ExperimentalFeaturesScreen({super.key});
  @override
  State<ExperimentalFeaturesScreen> createState() =>
      _ExperimentalFeaturesScreenState();
}

class _ExperimentalFeaturesScreenState
    extends State<ExperimentalFeaturesScreen> {
  ExperimentalFeatures get _exp =>
      AppState.instance.settings.experimental;

  Future<void> _save() async {
    await AppState.instance.persistSettingsOnly();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final exp = _exp;
    return Scaffold(
      appBar: AppBar(title: Text(tr('experimental_features'))),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Text(
              tr('experimental_subtitle'),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          _FeatureTile(
            icon: Icons.flag_outlined,
            title: tr('exp_priority'),
            subtitle: tr('exp_priority_desc'),
            value: exp.priority,
            onChanged: (v) {
              exp.priority = v;
              _save();
            },
          ),
          _FeatureTile(
            icon: Icons.map_outlined,
            title: tr('exp_global_map'),
            subtitle: tr('exp_global_map_desc'),
            value: exp.globalMap,
            onChanged: (v) {
              exp.globalMap = v;
              _save();
            },
          ),
          _FeatureTile(
            icon: Icons.image_outlined,
            title: tr('exp_export_graph_png'),
            subtitle: tr('exp_export_graph_png_desc'),
            value: exp.exportGraphPng,
            onChanged: (v) {
              exp.exportGraphPng = v;
              _save();
            },
          ),
          _FeatureTile(
            icon: Icons.label_outlined,
            title: tr('exp_case_tags'),
            subtitle: tr('exp_case_tags_desc'),
            value: exp.caseTags,
            onChanged: (v) {
              exp.caseTags = v;
              _save();
            },
          ),
          _FeatureTile(
            icon: Icons.map_outlined,
            title: tr('exp_export_map_png'),
            subtitle: tr('exp_export_map_png_desc'),
            value: exp.exportMapPng,
            onChanged: (v) {
              exp.exportMapPng = v;
              _save();
            },
          ),
          _FeatureTile(
            icon: Icons.picture_as_pdf_outlined,
            title: tr('exp_case_pdf'),
            subtitle: tr('exp_case_pdf_desc'),
            value: exp.casePdf,
            onChanged: (v) {
              exp.casePdf = v;
              _save();
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: SwitchListTile(
        secondary: Icon(
          icon,
          color: value ? theme.colorScheme.primary : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: value ? theme.colorScheme.primary : null,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

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
                          onPressed: () => _editMark(i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
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
    final mark = await _markDialog();
    if (mark != null) {
      AppState.instance.settings.marks.add(mark);
      await AppState.instance.persistSettingsOnly();
      if (mounted) setState(() {});
    }
  }

  Future<void> _editMark(int index) async {
    final existing = AppState.instance.settings.marks[index];
    final updated = await _markDialog(initial: existing);
    if (updated != null) {
      AppState.instance.settings.marks[index] = updated;
      await AppState.instance.persistSettingsOnly();
      if (mounted) setState(() {});
    }
  }

  Future<CustomMark?> _markDialog({CustomMark? initial}) async {
    final cChar = TextEditingController(text: initial?.char ?? '');
    final cLabel = TextEditingController(text: initial?.label ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('add_mark')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cChar,
              maxLength: 3,
              autofocus: true,
              decoration: InputDecoration(labelText: tr('mark_char')),
            ),
            TextField(
              controller: cLabel,
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
    if (ok == true && cChar.text.isNotEmpty) {
      return CustomMark(char: cChar.text, label: cLabel.text);
    }
    return null;
  }
}

// ============================================================================
// GRAPH SCREEN — per-case, custom force-directed non-overlapping layout
// ============================================================================

class GraphScreen extends StatefulWidget {
  final String caseId;
  const GraphScreen({super.key, required this.caseId});
  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  String? _reasonFilter;
  final _graphKey = GlobalKey<_ForceDirectedGraphViewState>();

  Set<String> _allReasons(CaseFile c) {
    final set = <String>{};
    for (final p in c.people) {
      for (final link in p.connections) {
        set.addAll(link.reasons);
      }
    }
    return set;
  }

  Future<void> _exportPng() async {
    try {
      final state = _graphKey.currentState;
      if (state == null) return;
      final bytes = await state.exportToPng();
      if (bytes == null) return;
      final f = File(
          '${AppState.instance.docsDir.path}/graph_${DateTime.now().millisecondsSinceEpoch}.png');
      await f.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(f.path)], text: 'OSINT V Graph');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppState.instance.findCase(widget.caseId);
    final exp = AppState.instance.settings.experimental;
    if (c == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('graph'))),
        body: const Center(child: Text('—')),
      );
    }

    final nodes = <_GraphNode>[
      for (final p in c.people) _GraphNode(id: p.id, label: p.fullName),
    ];
    final edgeKeys = <String>{};
    final edges = <_GraphEdge>[];
    for (final p in c.people) {
      for (final link in p.connections) {
        if (_reasonFilter != null &&
            !link.reasons.contains(_reasonFilter)) continue;
        if (c.findPerson(link.targetPersonId) == null) continue;
        final ids = [p.id, link.targetPersonId]..sort();
        final key = ids.join('|');
        if (edgeKeys.contains(key)) continue;
        edgeKeys.add(key);
        edges.add(_GraphEdge(fromId: p.id, toId: link.targetPersonId));
      }
    }

    final reasons = _allReasons(c).toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('graph')),
        actions: [
          if (exp.exportGraphPng)
            IconButton(
              tooltip: tr('export_graph_png'),
              icon: const Icon(Icons.image_outlined),
              onPressed: _exportPng,
            ),
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _reasonFilter = v),
            itemBuilder: (_) => [
              PopupMenuItem<String?>(
                  value: null, child: Text(tr('all_reasons'))),
              for (final r in reasons)
                PopupMenuItem<String?>(value: r, child: Text(r)),
            ],
          ),
        ],
      ),
      body: nodes.isEmpty
          ? Center(
              child: Text(tr('no_targets'),
                  style: const TextStyle(color: Colors.grey)),
            )
          : _ForceDirectedGraphView(
              key: _graphKey,
              nodes: nodes,
              edges: edges,
              onTapNode: (id) {
                final p = c.findPerson(id);
                if (p == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PersonScreen(caseId: c.id, personId: p.id),
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// CUSTOM FORCE-DIRECTED GRAPH (no overlap)
// ============================================================================

class _GraphNode {
  final String id;
  final String label;
  Offset position = Offset.zero;
  Size size = const Size(120, 44);
  _GraphNode({required this.id, required this.label});
}

class _GraphEdge {
  final String fromId;
  final String toId;
  _GraphEdge({required this.fromId, required this.toId});
}

class _ForceDirectedGraphView extends StatefulWidget {
  final List<_GraphNode> nodes;
  final List<_GraphEdge> edges;
  final void Function(String id) onTapNode;
  const _ForceDirectedGraphView({
    super.key,
    required this.nodes,
    required this.edges,
    required this.onTapNode,
  });

  @override
  State<_ForceDirectedGraphView> createState() =>
      _ForceDirectedGraphViewState();
}

class _ForceDirectedGraphViewState extends State<_ForceDirectedGraphView> {
  bool _laidOut = false;
  late Size _canvasSize;
  final TransformationController _transformController =
      TransformationController();
  final _repaintKey = GlobalKey();

  Future<Uint8List?> exportToPng() async {
    final boundary = _repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  void initState() {
    super.initState();
    _measureLabels();
  }

  void _measureLabels() {
    for (final n in widget.nodes) {
      final tp = TextPainter(
        text: TextSpan(
          text: n.label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: 220);
      final w = (tp.width + 24).clamp(80.0, 240.0);
      n.size = Size(w, 44);
    }
  }

  void _layout(Size canvas) {
    final n = widget.nodes.length;
    if (n == 0) return;

    final rng = math.Random(42);
    final cx = canvas.width / 2;
    final cy = canvas.height / 2;
    final r0 = math.min(canvas.width, canvas.height) * 0.32;
    for (var i = 0; i < n; i++) {
      final angle = (i / n) * 2 * math.pi + rng.nextDouble() * 0.2;
      widget.nodes[i].position =
          Offset(cx + r0 * math.cos(angle), cy + r0 * math.sin(angle));
    }

    if (n == 1) {
      widget.nodes[0].position = Offset(cx, cy);
      return;
    }

    final area = canvas.width * canvas.height;
    final k = math.sqrt(area / n) * 0.85;
    final minSpacing = _maxNodeRadius() * 2 + 30;

    final idToIndex = <String, int>{};
    for (var i = 0; i < n; i++) {
      idToIndex[widget.nodes[i].id] = i;
    }
    final edgePairs = <List<int>>[];
    for (final e in widget.edges) {
      final a = idToIndex[e.fromId];
      final b = idToIndex[e.toId];
      if (a == null || b == null || a == b) continue;
      edgePairs.add([a, b]);
    }

    final disp = List<Offset>.filled(n, Offset.zero);
    var temperature = math.min(canvas.width, canvas.height) / 8;
    const iterations = 500;

    for (var it = 0; it < iterations; it++) {
      for (var i = 0; i < n; i++) {
        disp[i] = Offset.zero;
      }

      for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          var delta = widget.nodes[i].position - widget.nodes[j].position;
          var d = delta.distance;
          if (d < 0.01) {
            final a = rng.nextDouble() * 2 * math.pi;
            delta = Offset(math.cos(a), math.sin(a)) * 0.5;
            d = 0.5;
          }
          double force = (k * k) / d;
          if (d < minSpacing) {
            final overlap = (minSpacing - d);
            force += overlap * overlap * 0.6;
          }
          final dir = delta / d;
          disp[i] = disp[i] + dir * force;
          disp[j] = disp[j] - dir * force;
        }
      }

      for (final pair in edgePairs) {
        final a = pair[0];
        final b = pair[1];
        var delta = widget.nodes[a].position - widget.nodes[b].position;
        var d = delta.distance;
        if (d < 0.01) d = 0.01;
        final force = (d * d) / k;
        final dir = delta / d;
        disp[a] = disp[a] - dir * force;
        disp[b] = disp[b] + dir * force;
      }

      for (var i = 0; i < n; i++) {
        final d = disp[i].distance;
        if (d > 0) {
          final capped = math.min(d, temperature);
          final move = disp[i] / d * capped;
          var pos = widget.nodes[i].position + move;
          final r = math.max(
                  widget.nodes[i].size.width, widget.nodes[i].size.height) /
              2;
          final x = pos.dx.clamp(r, canvas.width - r);
          final y = pos.dy.clamp(r, canvas.height - r);
          widget.nodes[i].position = Offset(x, y);
        }
      }

      temperature *= 0.985;
      if (temperature < 0.5) break;
    }

    for (var pass = 0; pass < 60; pass++) {
      var moved = false;
      for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          final a = widget.nodes[i];
          final b = widget.nodes[j];
          var delta = a.position - b.position;
          var d = delta.distance;
          final ra = math.sqrt(
                  a.size.width * a.size.width +
                      a.size.height * a.size.height) /
              2;
          final rb = math.sqrt(
                  b.size.width * b.size.width +
                      b.size.height * b.size.height) /
              2;
          final required = ra + rb + 14;
          if (d < required) {
            if (d < 0.01) {
              final ang = rng.nextDouble() * 2 * math.pi;
              delta = Offset(math.cos(ang), math.sin(ang));
              d = 1;
            }
            final shift = (required - d) / 2;
            final dir = delta / d;
            a.position = a.position + dir * shift;
            b.position = b.position - dir * shift;
            moved = true;
          }
        }
      }
      if (!moved) break;
    }

    for (final node in widget.nodes) {
      final r = math.max(node.size.width, node.size.height) / 2;
      final x = node.position.dx.clamp(r, canvas.width - r);
      final y = node.position.dy.clamp(r, canvas.height - r);
      node.position = Offset(x, y);
    }
  }

  double _maxNodeRadius() {
    double r = 0;
    for (final n in widget.nodes) {
      final cur = math.max(n.size.width, n.size.height) / 2;
      if (cur > r) r = cur;
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = widget.nodes.length;
        final base = math.max(900.0, math.sqrt(n) * 260);
        final w = math.max(constraints.maxWidth, base);
        final h = math.max(constraints.maxHeight, base * 0.75);
        final canvas = Size(w, h);

        if (!_laidOut || _canvasSize != canvas) {
          _canvasSize = canvas;
          _layout(canvas);
          _laidOut = true;
        }

        return InteractiveViewer(
          transformationController: _transformController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(400),
          minScale: 0.2,
          maxScale: 4,
          child: RepaintBoundary(
            key: _repaintKey,
            child: SizedBox(
              width: canvas.width,
              height: canvas.height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _EdgePainter(
                        nodes: widget.nodes,
                        edges: widget.edges,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  for (final node in widget.nodes)
                    Positioned(
                      left: node.position.dx - node.size.width / 2,
                      top: node.position.dy - node.size.height / 2,
                      width: node.size.width,
                      height: node.size.height,
                      child: _GraphNodeChip(
                        label: node.label,
                        onTap: () => widget.onTapNode(node.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EdgePainter extends CustomPainter {
  final List<_GraphNode> nodes;
  final List<_GraphEdge> edges;
  final Color color;
  _EdgePainter(
      {required this.nodes, required this.edges, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final byId = {for (final n in nodes) n.id: n};
    for (final e in edges) {
      final a = byId[e.fromId];
      final b = byId[e.toId];
      if (a == null || b == null) continue;
      canvas.drawLine(a.position, b.position, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter oldDelegate) =>
      oldDelegate.nodes != nodes || oldDelegate.edges != edges;
}

class _GraphNodeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GraphNodeChip({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.colorScheme.primary, width: 1.4),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CASE PDF BUILDER + PREVIEW
// ============================================================================

class CasePdfBuilder {
  static Future<Uint8List> buildCasePdf(
    CaseFile caseFile, {
    required bool withConnections,
    required bool withEvidence,
  }) async {
    final doc = pw.Document();
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pw.TextStyle ts(double size, {bool bold = false}) => pw.TextStyle(
          font: bold ? boldFont : baseFont,
          fontSize: size,
        );

    for (final p in caseFile.people) {
      final imageWidgets = <pw.Widget>[];
      if (withEvidence) {
        for (final ev in p.evidence) {
          for (final fp in ev.filePaths) {
            if (_isImagePath(fp)) {
              try {
                final bytes = await File(fp).readAsBytes();
                final img = pw.MemoryImage(bytes);
                imageWidgets.add(pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Image(img, height: 180, fit: pw.BoxFit.contain),
                      pw.Text(fp.split('/').last, style: ts(9)),
                    ],
                  ),
                ));
              } catch (_) {}
            }
          }
        }
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
          build: (ctx) {
            final widgets = <pw.Widget>[
              pw.Text('${caseFile.name}', style: ts(13, bold: true)),
              pw.SizedBox(height: 4),
              pw.Text(p.fullName, style: ts(20, bold: true)),
              pw.Divider(),
              pw.SizedBox(height: 8),
            ];

            if (p.priority != null) {
              widgets.add(pw.Text(
                  '${p.priority!.label}',
                  style: ts(11)));
              widgets.add(pw.SizedBox(height: 4));
            }

            if (p.tags.isNotEmpty) {
              widgets.add(
                  pw.Text('Tags: ${p.tags.join(', ')}', style: ts(11)));
              widgets.add(pw.SizedBox(height: 6));
            }
            if (p.notes.isNotEmpty) {
              widgets.add(pw.Text(p.notes, style: ts(11)));
              widgets.add(pw.SizedBox(height: 12));
            }

            for (final c in p.categories) {
              widgets.add(pw.SizedBox(height: 8));
              widgets.add(pw.Text(c.name, style: ts(14, bold: true)));
              widgets.add(pw.SizedBox(height: 4));
              for (final kv in c.entries) {
                widgets.add(pw.Bullet(
                    text: '${kv.key}: ${kv.value}', style: ts(11)));
              }
            }

            if (withEvidence && p.evidence.isNotEmpty) {
              widgets.add(pw.SizedBox(height: 14));
              widgets
                  .add(pw.Text('Evidence', style: ts(14, bold: true)));
              for (final ev in p.evidence) {
                widgets.add(pw.SizedBox(height: 6));
                widgets.add(pw.Text(ev.description, style: ts(11)));
                for (final fp in ev.filePaths) {
                  widgets.add(
                      pw.Text('• ${fp.split('/').last}', style: ts(10)));
                }
              }
              if (imageWidgets.isNotEmpty) {
                widgets.add(pw.SizedBox(height: 8));
                widgets.addAll(imageWidgets);
              }
            }

            if (withConnections && p.connections.isNotEmpty) {
              widgets.add(pw.SizedBox(height: 14));
              widgets.add(
                  pw.Text('Connections', style: ts(14, bold: true)));
              for (final link in p.connections) {
                final other = caseFile.findPerson(link.targetPersonId);
                widgets.add(pw.SizedBox(height: 4));
                widgets.add(pw.Text(other?.fullName ?? '?',
                    style: ts(12, bold: true)));
                for (final r in link.reasons) {
                  widgets.add(pw.Text('  - $r', style: ts(10)));
                }
              }
            }

            return widgets;
          },
        ),
      );
    }

    return doc.save();
  }
}

class CasePdfPreviewScreen extends StatelessWidget {
  final Uint8List bytes;
  final CaseFile caseFile;
  const CasePdfPreviewScreen(
      {super.key, required this.bytes, required this.caseFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF — ${caseFile.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final f = File(
                  '${AppState.instance.docsDir.path}/case_${caseFile.id}.pdf');
              await f.writeAsBytes(bytes);
              await Share.shareXFiles([XFile(f.path)]);
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              final f = File(
                  '${AppState.instance.docsDir.path}/case_${caseFile.id}.pdf');
              await f.writeAsBytes(bytes);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved: ${f.path}')),
                );
              }
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) async => bytes,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: false,
      ),
    );
  }
}

// ============================================================================
// PDF BUILDER + PREVIEW (per person)
// ============================================================================

class PdfBuilder {
  static Future<Uint8List> buildPersonPdf(
    Person p, {
    required CaseFile caseFile,
    required bool withConnections,
    required bool withEvidence,
  }) async {
    final doc = pw.Document();

    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pw.TextStyle ts(double size, {bool bold = false}) => pw.TextStyle(
          font: bold ? boldFont : baseFont,
          fontSize: size,
        );

    final imageWidgets = <pw.Widget>[];
    if (withEvidence) {
      for (final ev in p.evidence) {
        for (final fp in ev.filePaths) {
          if (_isImagePath(fp)) {
            try {
              final bytes = await File(fp).readAsBytes();
              final img = pw.MemoryImage(bytes);
              imageWidgets.add(pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Image(img, height: 220, fit: pw.BoxFit.contain),
                    pw.Text(fp.split('/').last, style: ts(9)),
                  ],
                ),
              ));
            } catch (_) {}
          }
        }
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        build: (ctx) {
          final widgets = <pw.Widget>[
            pw.Text('${tr('case_label')}: ${caseFile.name}', style: ts(11)),
            pw.SizedBox(height: 4),
            pw.Text(p.fullName, style: ts(22, bold: true)),
            pw.Divider(),
            pw.SizedBox(height: 8),
          ];

          if (p.tags.isNotEmpty) {
            widgets.add(pw.Text('Tags: ${p.tags.join(', ')}', style: ts(11)));
            widgets.add(pw.SizedBox(height: 6));
          }
          if (p.notes.isNotEmpty) {
            widgets.add(pw.Text(p.notes, style: ts(11)));
            widgets.add(pw.SizedBox(height: 12));
          }

          for (final c in p.categories) {
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(pw.Text(c.name, style: ts(14, bold: true)));
            widgets.add(pw.SizedBox(height: 4));
            for (final kv in c.entries) {
              widgets.add(pw.Bullet(
                  text: '${kv.key}: ${kv.value}', style: ts(11)));
            }
          }

          if (withEvidence && p.evidence.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 14));
            widgets.add(pw.Text(tr('evidence'), style: ts(14, bold: true)));
            for (final ev in p.evidence) {
              widgets.add(pw.SizedBox(height: 6));
              widgets.add(pw.Text(ev.description, style: ts(11)));
              for (final fp in ev.filePaths) {
                widgets.add(pw.Text('• ${fp.split('/').last}', style: ts(10)));
              }
            }
            if (imageWidgets.isNotEmpty) {
              widgets.add(pw.SizedBox(height: 8));
              widgets.addAll(imageWidgets);
            }
          }

          if (withConnections && p.connections.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 14));
            widgets.add(pw.Text(tr('connections'), style: ts(14, bold: true)));
            for (final link in p.connections) {
              final other = caseFile.findPerson(link.targetPersonId);
              widgets.add(pw.SizedBox(height: 4));
              widgets.add(pw.Text(other?.fullName ?? '?',
                  style: ts(12, bold: true)));
              for (final r in link.reasons) {
                widgets.add(pw.Text('  - $r', style: ts(10)));
              }
            }
          }

          return widgets;
        },
      ),
    );

    return doc.save();
  }
}

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List bytes;
  final Person person;
  final bool withEvidence;
  const PdfPreviewScreen({
    super.key,
    required this.bytes,
    required this.person,
    required this.withEvidence,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF — ${person.fullName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final f =
                  File('${AppState.instance.docsDir.path}/${person.id}.pdf');
              await f.writeAsBytes(bytes);
              final files = <XFile>[XFile(f.path)];
              if (withEvidence) {
                for (final ev in person.evidence) {
                  for (final fp in ev.filePaths) {
                    if (await File(fp).exists()) files.add(XFile(fp));
                  }
                }
              }
              await Share.shareXFiles(files);
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              final f =
                  File('${AppState.instance.docsDir.path}/${person.id}.pdf');
              await f.writeAsBytes(bytes);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved: ${f.path}')),
                );
              }
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) async => bytes,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: false,
      ),
    );
  }
}

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

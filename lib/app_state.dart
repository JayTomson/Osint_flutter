import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

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

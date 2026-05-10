import 'package:uuid/uuid.dart';
import 'person.dart';

const _uuid = Uuid();

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

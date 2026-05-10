import 'package:uuid/uuid.dart';
import 'key_value.dart';

const _uuid = Uuid();

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

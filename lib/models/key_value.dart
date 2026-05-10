import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class KeyValue {
  String id;
  String key;
  String value;

  KeyValue({String? id, this.key = '', this.value = ''})
      : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {'id': id, 'k': key, 'v': value};

  factory KeyValue.fromJson(Map<String, dynamic> j) => KeyValue(
        id: j['id'],
        key: j['k'] ?? '',
        value: j['v'] ?? '',
      );
}

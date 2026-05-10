import 'package:uuid/uuid.dart';

const _uuid = Uuid();

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

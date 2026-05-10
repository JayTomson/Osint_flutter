import 'package:uuid/uuid.dart';

const _uuid = Uuid();

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

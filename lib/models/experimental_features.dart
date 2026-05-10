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

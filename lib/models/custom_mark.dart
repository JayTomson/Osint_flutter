class CustomMark {
  String char;
  String label;

  CustomMark({required this.char, this.label = ''});

  Map<String, dynamic> toJson() => {'c': char, 'l': label};

  factory CustomMark.fromJson(Map<String, dynamic> j) => CustomMark(
        char: j['c'] ?? '',
        label: j['l'] ?? '',
      );
}

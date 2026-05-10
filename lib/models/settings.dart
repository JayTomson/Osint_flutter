import 'custom_mark.dart';
import 'experimental_features.dart';

enum AppTheme { light, dark, amoled }

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

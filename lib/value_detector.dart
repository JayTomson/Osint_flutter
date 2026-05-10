part of 'main.dart';

// ============================================================================
// VALUE DETECTOR
// ============================================================================

class ValueDetector {
  static LatLng? extractCoord(String text) {
    final re = RegExp(
        r'(-?\d{1,3}(?:[.,]\d+)?)\s*[,;]\s*(-?\d{1,3}(?:[.,]\d+)?)');
    final m = re.firstMatch(text);
    if (m == null) return null;
    final lat = double.tryParse(m.group(1)!.replaceAll(',', '.'));
    final lng = double.tryParse(m.group(2)!.replaceAll(',', '.'));
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90) return null;
    if (lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  static String? extractPhone(String text) {
    final re = RegExp(r'(?:\+?\d[\d\s\-().]{6,}\d)');
    final m = re.firstMatch(text);
    if (m == null) return null;
    final raw = m.group(0)!.replaceAll(RegExp(r'\s'), '');
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) return null;
    return raw;
  }

  static String? extractCard(String text) {
    final re = RegExp(r'\b(\d[\d\s\-]{13,17}\d)\b');
    final m = re.firstMatch(text);
    if (m == null) return null;
    final digits = m.group(1)!.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 16) return null;
    return digits;
  }

  static String? matchedCustomMark(String value) {
    final marks = AppState.instance.settings.marks;
    if (marks.isEmpty || value.isEmpty) return null;
    final trimmed = value.trimLeft();
    for (final mark in marks) {
      if (mark.char.isNotEmpty && trimmed.startsWith(mark.char)) {
        return mark.char;
      }
    }
    return null;
  }
}

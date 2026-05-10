import 'package:latlong2/latlong.dart';
import 'app_state.dart';

class ValueDetector {
  static final RegExp coordRe = RegExp(
    r'(-?\d{1,3}(?:\.\d+)?)\s*,\s*(-?\d{1,3}(?:\.\d+)?)',
  );
  static final RegExp phoneRe = RegExp(
    r'(\+\d[\d\s\-\(\)]{6,}\d)',
  );
  static final RegExp cardRe = RegExp(
    r'(?:\d{4}[\s-]?){3,4}\d{1,4}',
  );

  static LatLng? extractCoord(String value) {
    final m = coordRe.firstMatch(value.trim());
    if (m == null) return null;
    final lat = double.tryParse(m.group(1)!);
    final lng = double.tryParse(m.group(2)!);
    if (lat == null || lng == null) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return LatLng(lat, lng);
  }

  static String? extractPhone(String value) {
    final m = phoneRe.firstMatch(value);
    return m?.group(1);
  }

  static String? extractCard(String value) {
    final m = cardRe.firstMatch(value);
    if (m == null) return null;
    final digits = m.group(0)!.replaceAll(RegExp(r'\s|-'), '');
    if (digits.length < 13 || digits.length > 19) return null;
    return digits;
  }

  static String? matchedCustomMark(String value) {
    final marks = AppState.instance.settings.marks;
    final v = value.trimLeft();
    for (final m in marks) {
      if (m.char.isNotEmpty && v.startsWith(m.char)) return m.char;
    }
    return null;
  }
}

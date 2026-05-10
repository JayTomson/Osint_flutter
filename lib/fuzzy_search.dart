part of 'main.dart';

// ============================================================================
// FUZZY SEARCH
// ============================================================================

class FuzzySearch {
  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    final d = List.generate(
      s.length + 1,
      (i) => List.generate(t.length + 1, (j) => 0),
    );
    for (int i = 0; i <= s.length; i++) d[i][0] = i;
    for (int j = 0; j <= t.length; j++) d[0][j] = j;
    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost,
        ].reduce(math.min);
      }
    }
    return d[s.length][t.length];
  }

  static bool matches(String query, String text) {
    final q = query.toLowerCase().trim();
    final t = text.toLowerCase();
    if (q.isEmpty) return true;
    if (t.contains(q)) return true;
    if (q.length < 3) return false;
    final qWords = q.split(RegExp(r'\s+'));
    final tWords = t.split(RegExp(r'\W+'));
    for (final qw in qWords) {
      if (qw.length < 3) continue;
      final maxDist = qw.length <= 4 ? 1 : 2;
      bool wordFound = false;
      for (final tw in tWords) {
        if (tw.length < 2) continue;
        if (_levenshtein(qw, tw) <= maxDist) {
          wordFound = true;
          break;
        }
      }
      if (!wordFound) return false;
    }
    return qWords.any((w) => w.length >= 3);
  }
}

// ============================================================================
// SEARCH HIT
// ============================================================================

class SearchHit {
  final String location;
  final String snippet;
  const SearchHit({required this.location, required this.snippet});
}

List<SearchHit> findPersonHits(Person p, String query) {
  final q = query.toLowerCase().trim();
  if (q.isEmpty) return [];

  String snip(String text) {
    final lower = text.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx >= 0) {
      final s = math.max(0, idx - 15);
      final e = math.min(text.length, idx + q.length + 30);
      return '${s > 0 ? "…" : ""}${text.substring(s, e)}${e < text.length ? "…" : ""}';
    }
    return text.length > 60 ? '${text.substring(0, 57)}…' : text;
  }

  // Name matches are already visible on the card
  if (FuzzySearch.matches(q, p.name) ||
      FuzzySearch.matches(q, p.surname) ||
      FuzzySearch.matches(q, p.patronymic)) {
    return [];
  }

  final hits = <SearchHit>[];

  // Tags
  for (final t in p.tags) {
    if (FuzzySearch.matches(q, t)) {
      hits.add(SearchHit(location: tr('tags'), snippet: t));
    }
  }

  // Categories & key-values
  for (final c in p.categories) {
    if (FuzzySearch.matches(q, c.name)) {
      hits.add(SearchHit(location: tr('info'), snippet: c.name));
    }
    for (final kv in c.entries) {
      if (FuzzySearch.matches(q, kv.key)) {
        hits.add(SearchHit(location: c.name, snippet: kv.key));
      }
      if (kv.value.isNotEmpty && FuzzySearch.matches(q, kv.value)) {
        hits.add(SearchHit(
          location: '${c.name}${kv.key.isNotEmpty ? " → ${kv.key}" : ""}',
          snippet: snip(kv.value),
        ));
      }
    }
  }

  // Notes
  if (p.notes.isNotEmpty && FuzzySearch.matches(q, p.notes)) {
    hits.add(SearchHit(location: tr('notes'), snippet: snip(p.notes)));
  }

  // Evidence
  for (final ev in p.evidence) {
    if (ev.description.isNotEmpty && FuzzySearch.matches(q, ev.description)) {
      hits.add(SearchHit(
          location: tr('evidence'), snippet: snip(ev.description)));
    }
  }

  // Connections
  for (final conn in p.connections) {
    for (final r in conn.reasons) {
      if (FuzzySearch.matches(q, r)) {
        hits.add(SearchHit(location: tr('connections'), snippet: r));
      }
    }
  }

  return hits;
}

SearchHit? findPersonHit(Person p, String query) {
  final hits = findPersonHits(p, query);
  return hits.isEmpty ? null : hits.first;
}

bool personMatchesQuery(Person p, String query) {
  final q = query.toLowerCase().trim();
  if (q.isEmpty) return true;
  for (final s in p.searchHaystack()) {
    if (FuzzySearch.matches(q, s)) return true;
  }
  return false;
}

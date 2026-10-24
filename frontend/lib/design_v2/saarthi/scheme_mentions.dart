import '../../models/scheme_model.dart';

/// The catalog schemes a Saarthi reply names, in the order it names them.
///
/// The typed chat returns prose only, so its scheme cards come from the
/// catalog: a scheme counts as mentioned when its acronym or short name
/// (PMEGP, CGTMSE) appears as a whole word, or its name (English or Tamil,
/// or the full official name) appears anywhere. Run once per reply, not per frame.
List<Scheme> schemesMentionedIn(
  String reply,
  List<Scheme> catalog, {
  int limit = 2,
}) {
  if (reply.trim().isEmpty || catalog.isEmpty) return const [];
  final lower = reply.toLowerCase();
  final hits = <(int, Scheme)>[];
  final seen = <String>{};

  for (final s in catalog) {
    var at = -1;
    for (final token in _shortForms(s)) {
      final m = RegExp(
        '(?<![A-Za-z0-9])${RegExp.escape(token)}(?![A-Za-z0-9])',
        caseSensitive: false,
      ).firstMatch(reply);
      if (m != null && (at < 0 || m.start < at)) at = m.start;
    }
    for (final full in [s.name, s.nameTa, s.fullSchemeName]) {
      final f = _withoutParentheses(full).toLowerCase();
      if (f.length < 12) continue;
      final i = lower.indexOf(f);
      if (i >= 0 && (at < 0 || i < at)) at = i;
    }
    if (at >= 0 && seen.add(s.id)) hits.add((at, s));
  }
  hits.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final h in hits.take(limit)) h.$2];
}

final RegExp _parenthesised = RegExp(r'\(([^)]+)\)');

String _withoutParentheses(String text) =>
    text.replaceAll(_parenthesised, '').replaceAll(RegExp(r'\s+'), ' ').trim();

/// Acronyms worth matching as whole words: the short name and any
/// all-caps word in brackets ("Prime Minister's ... (PMEGP)").
Iterable<String> _shortForms(Scheme s) sync* {
  final short = s.shortName.trim();
  if (short.length >= 3 && short.length <= 16) yield short;
  for (final m in _parenthesised.allMatches(s.name)) {
    final inner = m[1]!.trim();
    if (inner.length >= 3 &&
        inner.length <= 12 &&
        !inner.contains(' ') &&
        inner == inner.toUpperCase()) {
      yield inner;
    }
  }
}

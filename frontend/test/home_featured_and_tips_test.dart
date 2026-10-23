// Home Featured slides (best matches, then newest schemes for the user's
// state) and the Tip of the Day rotation (the next tip on every app launch).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/screens/regular_mode/home/home_featured_section.dart';
import 'package:frontend/screens/regular_mode/home/home_updates_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

Scheme _s(String id, {String addedOn = '', bool national = true}) => Scheme(
  id: id,
  name: id,
  addedOn: addedOn,
  appliesNationally: national,
  stateCodes: national ? const [] : const ['IN-MH'],
);

void main() {
  test('best matches first, then the newest schemes not already shown', () {
    final a = _s('a', addedOn: '2026-10-17');
    final b = _s('b', addedOn: '2026-08-04');
    final c = _s('c', addedOn: '2026-10-14');
    final d = _s('d', addedOn: '2026-10-04');
    final slides = pickFeaturedSlides(
      ranked: [MapEntry(a, 82)],
      all: [a, b, c, d],
      state: 'Tamil Nadu',
      perKind: 2,
    );
    expect(slides.map((s) => s.scheme.id), ['a', 'c', 'd']);
    expect(slides.first.isNew, isFalse);
    expect(slides.first.matchPercent, 82);
    expect(slides.skip(1).every((s) => s.isNew), isTrue);
  });

  test('newest schemes from another state are left out', () {
    final mh = _s('mh', addedOn: '2026-10-20', national: false);
    final all = _s('all', addedOn: '2026-10-01');
    final slides = pickFeaturedSlides(
      ranked: const [],
      all: [mh, all],
      state: 'Tamil Nadu',
    );
    expect(slides.map((s) => s.scheme.id), ['all']);
  });

  test('schemes without a date are never shown as newly added', () {
    final slides = pickFeaturedSlides(
      ranked: const [],
      all: [_s('x')],
      state: '',
    );
    expect(slides, isEmpty);
  });

  test('ten distinct tips in every language', () async {
    for (final code in ['en', 'ta', 'hi']) {
      final l10n = await AppLocalizations.delegate.load(Locale(code));
      final tips = homeTips(l10n);
      expect(tips, hasLength(10));
      expect(tips.toSet(), hasLength(10), reason: code);
      expect(tips.every((t) => t.trim().isNotEmpty), isTrue);
    }
  });

  test('each app launch shows the next tip, wrapping after the last', () async {
    SharedPreferences.setMockInitialValues({HomeTipRotation.prefKey: 8});
    final seen = <int>[];
    for (var launch = 0; launch < 3; launch++) {
      HomeTipRotation.resetForTesting();
      seen.add(await HomeTipRotation.index(10));
      // The same launch keeps showing the same tip.
      expect(await HomeTipRotation.index(10), seen.last);
    }
    expect(seen, [8, 9, 0]);
  });
}

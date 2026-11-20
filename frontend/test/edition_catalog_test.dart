import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/config/edition.dart';
import 'package:frontend/models/scheme_filter.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/services/location_lock/location_lock.dart';

/// The Tamil Nadu and Maharashtra editions against the real bundled catalog:
/// Central schemes plus their own state's schemes, never the other state's,
/// and only their own state's languages.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    LocationScope.debugEnabledOverride = null;
    LocationScope.current.value = null;
    SchemeRepository.instance.clearCache();
  });

  for (final (edition, own, other, languages) in [
    (
      EditionConfig.maharashtra,
      'Maharashtra',
      'Tamil Nadu',
      ['en', 'hi', 'mr'],
    ),
    (EditionConfig.tamilNadu, 'Tamil Nadu', 'Maharashtra', ['en', 'ta']),
  ]) {
    test('${edition.appName}: Central + $own only, $own languages', () async {
      final repo = SchemeRepository.instance..clearCache();
      final everything = await repo.getAllSchemes();

      // A state edition build turns the state filter on (kEditionHasState).
      LocationScope.debugEnabledOverride = true;
      LocationScope.applyEdition(edition);
      final shown = await repo.getAllSchemes();

      final central = shown.where(schemeAppliesNationally).length;
      final ownOnly = shown
          .where((s) => !schemeAppliesNationally(s))
          .where((s) => schemeAppliesInState(s, own))
          .length;
      final otherOnly = shown
          .where((s) => !schemeAppliesNationally(s))
          .where((s) => schemeAppliesInState(s, other))
          .length;
      // ignore: avoid_print
      print(
        '${edition.appName}: ${shown.length} of ${everything.length} schemes '
        '= $central Central + $ownOnly $own, $otherOnly $other',
      );

      expect(central, greaterThan(0));
      expect(ownOnly, greaterThan(0));
      expect(otherOnly, 0, reason: 'no $other scheme in ${edition.appName}');
      expect(shown.every((s) => schemeAppliesInState(s, own)), isTrue);

      final hits = await repo.searchSchemeMatches('loan', langCode: 'en');
      expect(
        hits.where(
          (m) =>
              !schemeAppliesNationally(m.scheme) &&
              schemeAppliesInState(m.scheme, other),
        ),
        isEmpty,
        reason: 'search shows no $other scheme',
      );

      expect(LocationScope.allowedLanguages, languages);
      expect(LocationScope.restrictStates([own, other]), [own]);
    });
  }
}

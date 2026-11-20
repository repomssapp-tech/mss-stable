import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/scheme_filter.dart';
import 'package:frontend/services/catalog/scheme_repository.dart';
import 'package:frontend/services/location_lock/location_lock.dart';

LocationLock _lock(String code) => LocationLock(
  stateCode: code,
  latitude: 0,
  longitude: 0,
  verifiedAt: DateTime.utc(2026, 11, 18),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    LocationScope.debugEnabledOverride = null;
    LocationScope.current.value = null;
    SchemeRepository.instance.clearCache();
  });

  for (final (code, own, other) in [
    ('IN-MH', 'Maharashtra', 'Tamil Nadu'),
    ('IN-TN', 'Tamil Nadu', 'Maharashtra'),
  ]) {
    test('$own lock: central + $own schemes, none from $other', () async {
      final repo = SchemeRepository.instance..clearCache();
      final everything = await repo.getAllSchemes();
      final otherOnly = everything
          .where((s) => schemeAppliesInState(s, other))
          .where((s) => !schemeAppliesNationally(s))
          .length;
      expect(otherOnly, greaterThan(0), reason: 'catalog has $other schemes');

      LocationScope.debugEnabledOverride = true;
      LocationScope.current.value = _lock(code);
      final locked = await repo.getAllSchemes();

      expect(locked, isNotEmpty);
      expect(locked.length, lessThan(everything.length));
      expect(locked.every((s) => schemeAppliesInState(s, own)), isTrue);
      expect(
        locked.where(
          (s) => !schemeAppliesNationally(s) && schemeAppliesInState(s, other),
        ),
        isEmpty,
      );
      expect(locked.any(schemeAppliesNationally), isTrue);

      final hits = await repo.searchSchemeMatches('loan', langCode: 'en');
      expect(
        hits.where(
          (m) =>
              !schemeAppliesNationally(m.scheme) &&
              schemeAppliesInState(m.scheme, other),
        ),
        isEmpty,
      );
    });
  }
}

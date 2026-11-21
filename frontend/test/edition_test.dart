import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/config/edition.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/services/location_lock/location_lock.dart';
import 'package:frontend/services/updates/app_update_service.dart';

const _central = Scheme(id: 'CEN-1', name: 'PMEGP', appliesNationally: true);
const _maharashtra = Scheme(
  id: 'MH-1',
  name: 'CMEGP',
  state: 'Maharashtra',
  appliesNationally: false,
  stateCodes: ['IN-MH'],
);
const _tamilNadu = Scheme(
  id: 'TN-1',
  name: 'NEEDS',
  state: 'Tamil Nadu',
  appliesNationally: false,
  stateCodes: ['IN-TN'],
);

void main() {
  tearDown(() {
    LocationScope.current.value = null;
    LocationScope.debugEnabledOverride = null;
  });

  group('EditionConfig', () {
    test('a build without MSS_EDITION is the Central edition', () {
      expect(kEditionKey, 'central');
      expect(kEdition, same(EditionConfig.central));
      expect(kEditionHasState, isFalse);
    });

    test('keys map to editions; unknown keys fall back to Central', () {
      expect(EditionConfig.forKey('tn'), same(EditionConfig.tamilNadu));
      expect(EditionConfig.forKey(' MH '), same(EditionConfig.maharashtra));
      expect(EditionConfig.forKey('central'), same(EditionConfig.central));
      expect(EditionConfig.forKey('kerala'), same(EditionConfig.central));
    });

    test('each edition has its own state and language', () {
      expect(EditionConfig.central.stateCode, isNull);
      expect(EditionConfig.central.defaultLanguage, 'en');
      expect(EditionConfig.tamilNadu.stateCode, 'IN-TN');
      expect(EditionConfig.tamilNadu.defaultLanguage, 'ta');
      expect(EditionConfig.maharashtra.stateCode, 'IN-MH');
      expect(EditionConfig.maharashtra.defaultLanguage, 'mr');

      // One public stable repository; each edition takes its own APK there.
      for (final e in EditionConfig.all) {
        expect(e.releasesRepo, kStableReleasesRepo, reason: e.key);
      }
    });


    test('updates come from the public mss-stable repository', () {
      expect(AppUpdateService.releasesRepo, 'repomssapp-tech/mss-stable');
    });

    test('a state edition opens in a language its state offers', () {
      for (final e in EditionConfig.all) {
        final code = e.stateCode;
        if (code == null) continue;
        expect(
          LocationScope.languagesForState(code),
          contains(e.defaultLanguage),
          reason: e.key,
        );
      }
    });
  });

  group('LocationScope.applyEdition', () {
    test('Central edition leaves the app unlocked', () {
      LocationScope.applyEdition(EditionConfig.central);
      expect(LocationScope.current.value, isNull);
      expect(LocationScope.active, isFalse);
      expect(LocationScope.allowsScheme(_maharashtra), isTrue);
    });

    test('Maharashtra edition: MH and Central schemes, MH languages', () {
      LocationScope.debugEnabledOverride = true;
      LocationScope.applyEdition(EditionConfig.maharashtra);

      expect(LocationScope.stateName, 'Maharashtra');
      expect(LocationScope.allowsScheme(_central), isTrue);
      expect(LocationScope.allowsScheme(_maharashtra), isTrue);
      expect(LocationScope.allowsScheme(_tamilNadu), isFalse);
      expect(LocationScope.allowedLanguages, ['en', 'hi', 'mr']);
      expect(LocationScope.clampLanguage('ta'), 'en');
      expect(LocationScope.clampLanguage('mr'), 'mr');
    });

    test('Tamil Nadu edition: TN and Central schemes, TN languages', () {
      LocationScope.debugEnabledOverride = true;
      LocationScope.applyEdition(EditionConfig.tamilNadu);

      expect(LocationScope.stateName, 'Tamil Nadu');
      expect(LocationScope.allowsScheme(_central), isTrue);
      expect(LocationScope.allowsScheme(_tamilNadu), isTrue);
      expect(LocationScope.allowsScheme(_maharashtra), isFalse);
      expect(LocationScope.allowedLanguages, ['en', 'ta']);
      expect(
        LocationScope.restrictStates(['Maharashtra', 'Tamil Nadu', 'Kerala']),
        ['Tamil Nadu'],
      );
    });

    test('the fixed edition state carries no GPS address', () {
      LocationScope.applyEdition(EditionConfig.maharashtra);
      final lock = LocationScope.current.value!;
      expect(lock.address, isEmpty);
      expect(lock.city, isEmpty);
      expect(lock.pincode, isEmpty);
    });
  });
}

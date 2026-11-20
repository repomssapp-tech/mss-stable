import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/services/location_lock/location_lock.dart';
import 'package:frontend/services/location_lock/location_lock_service.dart';
import 'package:frontend/widgets/common/location_lock_gate.dart';
import 'package:geolocator/geolocator.dart';

LocationLock _lock(String code, {double lat = 19.07, double lng = 72.87}) =>
    LocationLock(
      stateCode: code,
      latitude: lat,
      longitude: lng,
      verifiedAt: DateTime.utc(2026, 11, 18, 10),
      address: 'Andheri East',
      city: 'Mumbai',
      district: 'Mumbai Suburban',
      pincode: '400069',
    );

Position _fix({
  double lat = 19.07,
  double lng = 72.87,
  double accuracy = 12,
  bool mocked = false,
}) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime.utc(2026, 11, 18, 10),
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
  isMocked: mocked,
);

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
const _unknown = Scheme(id: 'X-1', name: 'Unknown coverage', state: '');

void main() {
  setUp(() => LocationScope.debugEnabledOverride = true);
  tearDown(() {
    LocationScope.debugEnabledOverride = null;
    LocationScope.current.value = null;
  });

  group('LocationScope', () {
    test('is inactive until a lock exists', () {
      expect(LocationScope.active, isFalse);
      expect(LocationScope.allowsScheme(_tamilNadu), isTrue);
      expect(LocationScope.allowedLanguages, isNull);
      expect(LocationScope.clampLanguage('ta'), 'ta');
    });

    test('is inactive in a build without the lock', () {
      LocationScope.debugEnabledOverride = false;
      LocationScope.current.value = _lock('IN-MH');
      expect(LocationScope.active, isFalse);
      expect(LocationScope.allowsScheme(_tamilNadu), isTrue);
    });

    test('Maharashtra: central + Maharashtra schemes only', () {
      LocationScope.current.value = _lock('IN-MH');
      expect(LocationScope.allowsScheme(_central), isTrue);
      expect(LocationScope.allowsScheme(_maharashtra), isTrue);
      expect(LocationScope.allowsScheme(_tamilNadu), isFalse);
      expect(LocationScope.allowsScheme(_unknown), isFalse);
    });

    test('Tamil Nadu: central + Tamil Nadu schemes only', () {
      LocationScope.current.value = _lock('IN-TN', lat: 13.08, lng: 80.27);
      expect(LocationScope.allowsScheme(_central), isTrue);
      expect(LocationScope.allowsScheme(_tamilNadu), isTrue);
      expect(LocationScope.allowsScheme(_maharashtra), isFalse);
    });

    test('languages: English first, then the state languages', () {
      expect(LocationScope.languagesForState('IN-MH'), ['en', 'hi', 'mr']);
      expect(LocationScope.languagesForState('IN-TN'), ['en', 'ta']);
      expect(LocationScope.languagesForState('IN-KA'), ['en', 'hi']);
    });

    test('a language the state does not offer falls back to English', () {
      LocationScope.current.value = _lock('IN-MH');
      expect(LocationScope.clampLanguage('mr'), 'mr');
      expect(LocationScope.clampLanguage('hi'), 'hi');
      expect(LocationScope.clampLanguage('ta'), 'en');
      LocationScope.current.value = _lock('IN-TN');
      expect(LocationScope.clampLanguage('ta'), 'ta');
      expect(LocationScope.clampLanguage('mr'), 'en');
      expect(LocationScope.clampLanguage('hi'), 'en');
    });

    test('state lists shrink to the locked state', () {
      LocationScope.current.value = _lock('IN-MH');
      expect(
        LocationScope.restrictStates(['Tamil Nadu', 'Maharashtra', 'Goa']),
        ['Maharashtra'],
      );
      expect(LocationScope.restrictStates(['Goa']), ['Maharashtra']);
    });
  });

  group('LocationLock', () {
    test('survives a save and load', () {
      final lock = _lock('IN-MH');
      final back = LocationLock.decode(lock.encode())!;
      expect(back.stateCode, 'IN-MH');
      expect(back.stateName, 'Maharashtra');
      expect(back.pincode, '400069');
      expect(back.verifiedAt, lock.verifiedAt);
    });

    test('rejects damaged or unknown data', () {
      expect(LocationLock.decode(null), isNull);
      expect(LocationLock.decode('not json'), isNull);
      expect(
        LocationLock.decode('{"stateCode":"IN-ZZ","lat":1,"lng":2}'),
        isNull,
      );
    });
  });

  group('assessPosition', () {
    final now = DateTime.utc(2026, 11, 18, 10);

    test('accepts a normal GPS fix', () {
      expect(LocationLockService.assessPosition(_fix(), now: now), isNull);
    });

    test('rejects a fake-GPS (mock) fix', () {
      expect(
        LocationLockService.assessPosition(_fix(mocked: true), now: now),
        LocationCheckFailure.mockLocation,
      );
    });

    test('rejects a fix too vague to place in a state', () {
      expect(
        LocationLockService.assessPosition(_fix(accuracy: 5000), now: now),
        LocationCheckFailure.lowAccuracy,
      );
    });

    test('rejects a teleport from Mumbai to Chennai in 10 minutes', () {
      final previous = _lock('IN-MH');
      expect(
        LocationLockService.assessPosition(
          _fix(lat: 13.08, lng: 80.27),
          previous: previous,
          now: previous.verifiedAt.add(const Duration(minutes: 10)),
        ),
        LocationCheckFailure.impossibleJump,
      );
    });

    test('allows the same trip a day later', () {
      final previous = _lock('IN-MH');
      expect(
        LocationLockService.assessPosition(
          _fix(lat: 13.08, lng: 80.27),
          previous: previous,
          now: previous.verifiedAt.add(const Duration(days: 1)),
        ),
        isNull,
      );
    });

    test('allows GPS drift right after the last check', () {
      final previous = _lock('IN-MH');
      expect(
        LocationLockService.assessPosition(
          _fix(lat: 19.08, lng: 72.88),
          previous: previous,
          now: previous.verifiedAt.add(const Duration(seconds: 5)),
        ),
        isNull,
      );
    });
  });

  test('VPN tunnel interfaces are recognised', () {
    for (final name in ['tun0', 'wg0', 'ppp0', 'ipsec1', 'tap0']) {
      expect(
        LocationLockService.looksLikeVpnInterface(name),
        isTrue,
        reason: name,
      );
    }
    for (final name in ['wlan0', 'rmnet_data0', 'eth0', 'ccmni1']) {
      expect(
        LocationLockService.looksLikeVpnInterface(name),
        isFalse,
        reason: name,
      );
    }
  });

  testWidgets('blocked screen explains a mock location and offers a retry', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LocationRequiredScreen(
          failure: LocationCheckFailure.mockLocation,
          checking: false,
          onRetry: () => retried = true,
        ),
      ),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.locationErrMock), findsOneWidget);
    await tester.tap(find.text(l10n.locationGateRetry));
    expect(retried, isTrue);
  });

  test('every failure has a message in every language', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final f in LocationCheckFailure.values) {
        expect(
          LocationRequiredScreen.message(l10n, f),
          isNotEmpty,
          reason: '${locale.languageCode} $f',
        );
      }
    }
  });
}

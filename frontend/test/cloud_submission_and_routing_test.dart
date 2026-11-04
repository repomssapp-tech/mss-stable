import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cloud-confirmed onboarding', () {
    for (final path in <String>[
      'lib/screens/regular_mode/basic_profile_screen.dart',
      'lib/screens/companion_mode/saarthi_welcome_screen.dart',
    ]) {
      test('$path waits for cloud confirmation before routing', () {
        final source = File(path).readAsStringSync();
        final saveIndex = source.indexOf('await provider.updateProfile(');
        final cloudIndex = source.indexOf('requireCloudSync: true');
        final routeIndex = source.indexOf('pushAndRemoveUntil(');

        expect(saveIndex, greaterThanOrEqualTo(0));
        expect(cloudIndex, greaterThan(saveIndex));
        expect(routeIndex, greaterThan(cloudIndex));
        // The save-failure notice is either an inline literal or, once the
        // screen is migrated onto gen-l10n, an ARB key reference.
        expect(
          source.toLowerCase().contains('unable to save') ||
              source.contains('welcomeSavePreferencesError') ||
              source.contains('profileErrUnableToSave'),
          isTrue,
          reason: 'expected a visible save-failure message in $path',
        );
      });
    }

    test('profile sync is REST-only and reports failures to the caller', () {
      final source = File(
        'lib/providers/controllers/profile_cloud_sync.dart',
      ).readAsStringSync();

      expect(source, contains('Future<void> syncProfileToServer('));
      expect(source, contains('ProfileApiService.instance.saveProfileChanges'));
      expect(
        source,
        contains('OnboardingApiService.instance.submitOnboarding'),
      );
      // A failed server write must reach updateProfile(requireCloudSync: true)
      // instead of being swallowed, or onboarding could finish unsaved.
      expect(source, isNot(contains('catch (')));
    });
  });

  test('interactive controls do not contain empty callbacks', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final emptyHandler = RegExp(
      r'on(?:Pressed|Tap):\s*\(\)\s*(?:async\s*)?\{\s*\}',
      multiLine: true,
    );

    final offenders = <String>[];
    for (final file in dartFiles) {
      if (emptyHandler.hasMatch(file.readAsStringSync())) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty, reason: 'Empty handlers found in $offenders');
  });

  test('login legal links and scheme share control have real actions', () {
    final login = File('lib/screens/login_screen.dart').readAsStringSync();
    final details = File(
      'lib/screens/regular_mode/scheme_details_screen.dart',
    ).readAsStringSync();

    expect(login, contains('TermsConditionsScreen'));
    expect(login, contains('PrivacyPolicyScreen'));
    expect(details, contains('onPressed: () => _copySchemeDetails(scheme)'));
    // Opens the share sheet (copies only where none exists): BUG-10.
    expect(details, contains('shareText('));
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_profile.dart';

void main() {
  group('cloud-confirmed onboarding', () {
    test('profile payload matches the hosted Supabase contract', () {
      final payload = UserProfile(
        googleUserId: '00000000-0000-0000-0000-000000000001',
        name: 'Test User',
        profileCompleted: true,
      ).toSupabase();

      expect(
        payload.keys,
        containsAll(<String>[
          'id',
          'email',
          'name',
          'language',
          'navigation_mode',
          'applicant_type',
          'state',
          'district',
          'pincode',
          'is_profile_complete',
          'dob',
          'gender',
          'qualification',
          'annual_income',
          'community',
          'phone',
          'updated_at',
        ]),
      );
      expect(payload['id'], isNotEmpty);
      expect(payload['is_profile_complete'], isTrue);
    });

    for (final path in <String>[
      'lib/screens/regular_mode/about_you_profile_screen.dart',
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
        expect(source, contains('could not save'));
      });
    }

    test('completion flag is finalized after startup profile upsert', () {
      final source = File(
        'lib/providers/app_state_provider.dart',
      ).readAsStringSync();
      final stagedIndex = source.indexOf('final stagedProfile');
      final startupIndex = source.indexOf(
        ".from('startup_profiles')",
        stagedIndex,
      );
      final finalProfileIndex = source.indexOf(
        'createProfile(cloudProfile)',
        startupIndex,
      );

      expect(stagedIndex, greaterThanOrEqualTo(0));
      expect(startupIndex, greaterThan(stagedIndex));
      expect(finalProfileIndex, greaterThan(startupIndex));
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
    expect(details, contains('Clipboard.setData'));
  });
}

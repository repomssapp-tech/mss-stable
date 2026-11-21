import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/providers/controllers/profile_completion.dart';

UserProfile _complete({String house = '12 Main Road', String area = ''}) =>
    UserProfile(
      name: 'Test User',
      mobile: '9876543210',
      email: 'test@example.com',
      dob: DateTime(1990, 1, 1),
      gender: 'Female',
      house: house,
      area: area,
      city: 'Chennai',
      district: 'Chennai',
      state: 'Tamil Nadu',
      pinCode: '600001',
      employmentStatus: 'Individual',
      educationLevel: 'Graduate',
      community: 'General',
      disability: 'No',
    );

void main() {
  group('profile completion and the single address line (#149)', () {
    test('a profile restored from the server (house only) is complete', () {
      final p = _complete();
      expect(calculateProfileCompletionPercentage(p), 100);
      expect(calculateMissingProfileSections(p), isEmpty);
    });

    test(
      'a completed server profile can omit the optional disability field',
      () {
        final restored = _complete().copyWith(
          disability: 'None',
          profileCompleted: true,
        );
        expect(calculateProfileCompletionPercentage(restored), 100);
        expect(calculateMissingProfileSections(restored), isEmpty);

        final incomplete = restored.copyWith(community: '');
        expect(calculateProfileCompletionPercentage(incomplete), lessThan(100));
        expect(
          calculateMissingProfileSections(incomplete),
          contains('Eligibility'),
        );
      },
    );

    test('an area-only profile also counts as having an address', () {
      final p = _complete(house: '', area: '12 Main Road');
      expect(calculateProfileCompletionPercentage(p), 100);
      expect(calculateMissingProfileSections(p), isEmpty);
    });

    test('no address line at all is still reported as missing', () {
      final p = _complete(house: '', area: '');
      expect(calculateProfileCompletionPercentage(p), lessThan(100));
      expect(calculateMissingProfileSections(p), contains('Address Details'));
    });
  });
}

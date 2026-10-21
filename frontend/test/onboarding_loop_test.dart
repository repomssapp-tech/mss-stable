import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/providers/app_state_provider.dart';

/// Issue #123: after signing in again, onboarding re-ran on every launch
/// because the server keeps is_profile_complete=false until legal consent is
/// recorded, even though every profile field is saved.
void main() {
  UserProfile filled({bool completed = false}) => UserProfile(
    name: 'Asha Kumar',
    email: 'asha@example.com',
    dob: DateTime(1990, 5, 1),
    gender: 'Female',
    mobile: '9876543210',
    state: 'Tamil Nadu',
    district: 'Chennai',
    city: 'Chennai',
    pinCode: '600001',
    house: '12 Main Road',
    employmentStatus: 'MSME Owner',
    educationLevel: 'Graduate',
    qualification: 'Graduate',
    community: 'General',
    annualIncome: 300000,
    profileCompleted: completed,
  );

  group('completedPendingConsent', () {
    test('every field saved, only consent missing on the server: complete', () {
      expect(
        AppProvider.completedPendingConsent(filled(), const [
          'legal_acceptances',
        ]),
        isTrue,
      );
      expect(AppProvider.completedPendingConsent(filled(), const []), isTrue);
    });

    test('a profile field missing on the server: still onboarding', () {
      expect(
        AppProvider.completedPendingConsent(filled(), const [
          'annual_income',
          'legal_acceptances',
        ]),
        isFalse,
      );
    });

    test('a required field missing on this device: still onboarding', () {
      final noPhone = filled().copyWith(mobile: '');
      expect(AppProvider.completedPendingConsent(noPhone, const []), isFalse);
      final noCommunity = filled().copyWith(community: '');
      expect(
        AppProvider.completedPendingConsent(noCommunity, const []),
        isFalse,
      );
    });

    test('already complete: nothing to change', () {
      expect(
        AppProvider.completedPendingConsent(filled(completed: true), const []),
        isFalse,
      );
    });

    test('a brand-new account is not treated as complete', () {
      expect(
        AppProvider.completedPendingConsent(UserProfile(), const [
          'dob',
          'gender',
          'phone',
        ]),
        isFalse,
      );
    });
  });

  test('only legal / consent / terms / privacy count as consent fields', () {
    expect(
      AppProvider.profileFieldsCompleteOnServer(const [
        'legal_acceptances',
        'consent',
        'terms',
        'privacy_policy',
      ]),
      isTrue,
    );
    expect(AppProvider.profileFieldsCompleteOnServer(const ['state']), isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/engine/recommendation_engine.dart';

void main() {
  group('For Me Profile Eligibility Logic Tests', () {
    test('Male user is NOT eligible for Women-only schemes', () {
      final maleProfile = UserProfile(
        gender: 'Male',
        state: 'Tamil Nadu',
        dob: DateTime(1998, 1, 1),
        community: 'General',
      );

      final womenScheme = Scheme(
        id: 'STANDUP_INDIA',
        name: 'Stand-Up India',
        category: 'Women Entrepreneurs',
        overview: 'Loans for women and SC/ST entrepreneurs',
        sponsoringBody: 'Ministry of Finance',
        state: 'All India',
        targetBeneficiary: 'Women, SC, ST',
      );

      final result = RecommendationEngine.evaluate(maleProfile, womenScheme);
      expect(result.score, equals(0.0));
      expect(result.missingRequirements.isNotEmpty, isTrue);
    });

    test('Female user IS eligible for Women-only schemes', () {
      final femaleProfile = UserProfile(
        gender: 'Female',
        state: 'Tamil Nadu',
        dob: DateTime(1998, 1, 1),
        community: 'General',
      );

      final womenScheme = Scheme(
        id: 'STANDUP_INDIA',
        name: 'Stand-Up India',
        category: 'Women Entrepreneurs',
        overview: 'Loans for women and SC/ST entrepreneurs',
        sponsoringBody: 'Ministry of Finance',
        state: 'All India',
        targetBeneficiary: 'Women, SC, ST',
      );

      final result = RecommendationEngine.evaluate(femaleProfile, womenScheme);
      expect(result.score, greaterThanOrEqualTo(0.4));
    });

    test('Non-TN resident is NOT eligible for Tamil Nadu specific schemes (NEEDS)', () {
      final karnatakaProfile = UserProfile(
        gender: 'Male',
        state: 'Karnataka',
        dob: DateTime(2000, 1, 1),
        educationLevel: 'Graduate',
        community: 'General',
      );

      final needsScheme = Scheme(
        id: 'NEEDS',
        name: 'New Entrepreneur-cum-Enterprise Development Scheme',
        category: 'Business & MSME',
        overview: 'Assistance for first generation entrepreneurs in Tamil Nadu',
        sponsoringBody: 'Government of Tamil Nadu',
        state: 'Tamil Nadu',
        targetBeneficiary: 'Entrepreneurs',
      );

      final result = RecommendationEngine.evaluate(karnatakaProfile, needsScheme);
      expect(result.score, equals(0.0));
      expect(result.missingRequirements.any((r) => r.contains('Tamil Nadu')), isTrue);
    });

    test('TN resident graduate IS eligible for NEEDS scheme', () {
      final tnProfile = UserProfile(
        gender: 'Male',
        state: 'Tamil Nadu',
        dob: DateTime(2000, 1, 1),
        educationLevel: 'Graduate',
        community: 'General',
      );

      final needsScheme = Scheme(
        id: 'NEEDS',
        name: 'New Entrepreneur-cum-Enterprise Development Scheme',
        category: 'Business & MSME',
        overview: 'Assistance for first generation entrepreneurs in Tamil Nadu',
        sponsoringBody: 'Government of Tamil Nadu',
        state: 'Tamil Nadu',
        targetBeneficiary: 'Entrepreneurs',
      );

      final result = RecommendationEngine.evaluate(tnProfile, needsScheme);
      expect(result.score, greaterThanOrEqualTo(0.4));
    });

    test('Exact count consistency between computed eligible count and filtered list count', () {
      // NOTE: under the additive engine a scheme must have at least one
      // SUBSTANTIVELY matched facet to clear the gate — a fixture with zero
      // eligibility data no longer passes just because the engine defaults
      // high (that was the Phase 2 bug). So TN_1 / ALL_1 / KA_1 now declare
      // an age range this profile (age ~30) satisfies. The test's actual
      // intent is unchanged: a state mismatch (KA_1) and a gender/category
      // mismatch (STANDUP_INDIA for a Male OBC) are still hard-excluded, and
      // exactly the two control schemes pass.
      final profile = UserProfile(
        gender: 'Male',
        state: 'Tamil Nadu',
        dob: DateTime(1995, 5, 20),
        community: 'OBC',
        educationLevel: 'Graduate',
      );

      final schemes = [
        Scheme(
          id: 'TN_1',
          name: 'TN Scheme 1',
          state: 'Tamil Nadu',
          category: 'MSME',
          sponsoringBody: 'TN Govt',
          eligibilityMinAge: 18,
          eligibilityMaxAge: 45,
        ),
        Scheme(
          id: 'ALL_1',
          name: 'Central Scheme 1',
          state: 'All India',
          category: 'MSME',
          sponsoringBody: 'MSME',
          eligibilityMinAge: 18,
          eligibilityMaxAge: 45,
        ),
        Scheme(
          id: 'KA_1',
          name: 'Karnataka Scheme 1',
          state: 'Karnataka',
          category: 'MSME',
          sponsoringBody: 'KA Govt',
          eligibilityMinAge: 18,
          eligibilityMaxAge: 45,
        ),
        Scheme(
          id: 'STANDUP_INDIA',
          name: 'Stand-Up India (Women/SC/ST)',
          state: 'All India',
          category: 'Women Entrepreneurs',
          sponsoringBody: 'Finance',
        ),
      ];

      final recs = RecommendationEngine.getRecommendations(profile, schemes);
      final eligibleList = recs.where((e) => e.value.score > 0.35).map((e) => e.key).toList();

      // Karnataka and StandUp (for Male OBC) must be excluded
      expect(eligibleList.map((s) => s.id).toList(), containsAll(['TN_1', 'ALL_1']));
      expect(eligibleList.map((s) => s.id).toList(), isNot(contains('KA_1')));
      expect(eligibleList.map((s) => s.id).toList(), isNot(contains('STANDUP_INDIA')));
      expect(eligibleList.length, equals(2));
    });
  });
}

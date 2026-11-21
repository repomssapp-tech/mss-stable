import '../../models/user_profile.dart';

class QuestionnaireProfileUpdate {
  const QuestionnaireProfileUpdate._();

  static UserProfile? apply(UserProfile profile, Map<String, Object?> answers) {
    final state =
        answers['general_state'] as String? ??
        (_isMaharashtraResident(answers) ? 'Maharashtra' : null);
    final gender = _gender(
      answers['general_gender'] ?? answers['owner_gender'],
    );
    final community = _community(answers['social_category']);
    final industry = _industry(answers['business_nature'] as String?);
    if (state == null &&
        gender == null &&
        community == null &&
        industry == null) {
      return null;
    }
    return profile.copyWith(
      state: state,
      gender: gender,
      community: community,
      businessIndustry: industry,
    );
  }

  static bool _isMaharashtraResident(Map<String, Object?> answers) {
    final answer = answers['is_maharashtra_domicile'];
    return answer is Map<String, Object?> && answer['resident'] == true;
  }

  static String? _gender(Object? answer) => switch (answer) {
    'woman' => 'Female',
    'man' => 'Male',
    'other' => 'Other',
    _ => null,
  };

  static String? _community(Object? answer) {
    if (answer is! List<Object?> || answer.length != 1) return null;
    return switch (answer.single) {
      'general' => 'General',
      'sc' => 'SC',
      'st' => 'ST',
      'obc' => 'OBC',
      'minority' => 'Minority',
      _ => null,
    };
  }

  static String? _industry(String? answer) => switch (answer) {
    'manufacturing' => 'Manufacturing',
    'services' => 'Services',
    'trading_retail' => 'Trading / Retail',
    'agro_food_processing' => 'Agro / Food Processing',
    _ => null,
  };
}

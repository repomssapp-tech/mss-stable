import '../../models/questionnaire.dart';
import '../../models/user_profile.dart';
import '../recommendation/indian_states.dart';
import '../recommendation/profile_canonicalizer.dart';

class QuestionnaireProfilePrefill {
  static Object? valueFor(QuestionnaireField field, UserProfile profile) {
    final value = switch (field.id) {
      'general_state' => _knownState(profile.state),
      'general_gender' || 'owner_gender' => _gender(profile.gender),
      'social_category' => _socialCategories(field, profile),
      'business_nature' => _businessNature(field, profile.businessIndustry),
      'business_age' => _businessAge(field, profile),
      'owner_age' => _age(field, profile),
      'education_level' => _education(
        field,
        profile.educationLevel.isEmpty
            ? profile.qualification
            : profile.educationLevel,
      ),
      'existing_registrations' => _registrations(
        field,
        profile.registrationNumbers,
      ),
      'preferred_app_language' => _option(field, profile.language),
      _ => null,
    };
    return value;
  }

  static String? _knownState(String state) {
    final canonical = IndianStates.canonical(state);
    if (IndianStates.names.contains(canonical)) return canonical;
    final code = IndianStates.code(state);
    return code == null ? null : IndianStates.nameForCode(code);
  }

  static String? _gender(String gender) {
    final value = gender.trim().toLowerCase();
    if (value.contains('female') || value.contains('woman')) return 'woman';
    if (value.contains('male') || value == 'man') return 'man';
    if (value.contains('trans') || value.contains('other')) return 'other';
    return null;
  }

  static List<String>? _socialCategories(
    QuestionnaireField field,
    UserProfile profile,
  ) {
    final categories = <String>[];
    final community = profile.community.toLowerCase();
    if (community.contains('general') || community == 'open') {
      categories.add('general');
    }
    if (community == 'sc' ||
        community.startsWith('sc/') ||
        community.endsWith('/sc') ||
        community.contains('scheduled caste')) {
      categories.add('sc');
    }
    if (community == 'st' ||
        community.startsWith('st/') ||
        community.endsWith('/st') ||
        community.contains('scheduled tribe')) {
      categories.add('st');
    }
    if (community.contains('obc') ||
        community.contains('backward') ||
        community == 'bc') {
      categories.add('obc');
    }
    if (ProfileCanonicalizer.isDifferentlyAbled(profile.disability)) {
      categories.add('person_with_disability_divyangjan');
    }
    if (profile.veteran) categories.add('ex_serviceman');
    return categories.isEmpty ? null : _options(field, categories);
  }

  static String? businessArea(UserProfile profile) {
    final area = profile.area.toLowerCase();
    if (area.contains('rural') || area.contains('village')) {
      return 'village_rural';
    }
    if (area.contains('town')) return 'town';
    if (area.contains('urban') || area.contains('city')) return 'city_urban';
    return null;
  }

  static String? _businessNature(QuestionnaireField field, String industry) {
    final value = industry.toLowerCase();
    if (value.contains('manufactur')) return _option(field, 'manufacturing');
    if (value.contains('service')) return _option(field, 'services');
    if (value.contains('trad') || value.contains('retail')) {
      return _option(field, 'trading_retail');
    }
    if (value.contains('agro') || value.contains('food')) {
      return _option(field, 'agro_food_processing');
    }
    return null;
  }

  static String? _businessAge(QuestionnaireField field, UserProfile profile) {
    final stage = profile.businessStage.toLowerCase();
    if (stage.contains('idea') || stage.contains('not started')) {
      return _option(field, 'not_started_yet_aspiring');
    }
    return null;
  }

  static int? _age(QuestionnaireField field, UserProfile profile) {
    final dob = profile.dob;
    if (dob == null) return null;
    final today = DateTime.now();
    var age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    final min = field.answerRules['min'] as int? ?? 18;
    final max = field.answerRules['max'] as int? ?? 99;
    return age >= min && age <= max ? age : null;
  }

  static String? _education(QuestionnaireField field, String education) {
    final value = education.toLowerCase();
    if (value.isEmpty) return null;
    if (value.contains('graduate') ||
        value.contains('bachelor') ||
        value == 'ph.d.') {
      return _option(field, 'graduate_or_above');
    }
    if (value.contains('diploma') || value.contains('iti')) {
      return _option(field, '12th_iti_diploma');
    }
    if (value.contains('12') || value.contains('higher secondary')) {
      return _option(field, '12th_iti_diploma');
    }
    if (value.contains('10') || value.contains('secondary')) {
      return _option(field, '10th_pass');
    }
    if (value.contains('7') || value.contains('school')) {
      return _option(field, 'below_7th_pass');
    }
    return null;
  }

  static List<String>? _registrations(
    QuestionnaireField field,
    String registrations,
  ) {
    final normalized = registrations.toLowerCase();
    final values = <String>[];
    for (final option in field.options) {
      if (normalized.contains(option.value.replaceAll('_', ' ')) ||
          normalized.contains(option.value.replaceAll('_', ''))) {
        values.add(option.value);
      }
    }
    return values.isEmpty ? null : values;
  }

  static String? _option(QuestionnaireField field, String value) =>
      _hasOption(field, value) ? value : null;

  static List<String>? _options(QuestionnaireField field, List<String> values) {
    final valid = values.where((value) => _hasOption(field, value)).toList();
    return valid.isEmpty ? null : valid;
  }

  static bool _hasOption(QuestionnaireField field, String value) =>
      field.options.any((option) => option.value == value);
}

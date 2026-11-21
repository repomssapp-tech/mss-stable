import 'dart:convert';

import 'package:flutter/services.dart';

import 'user_profile.dart';

/// The MSS profile questionnaire (assets/questionnaire/questionnaire.json, written by
/// repo-web-new/tools/questionnaire_v2.py; the website and the server use the same file).
/// Question text and options carry English, Marathi, Hindi and Tamil. Answers are stored
/// by option `value` key, never by display text, so they survive a language switch.
const questionnaireLanguages = <String>['en', 'mr', 'hi', 'ta'];

/// An answer map: field id to a String, a list of Strings, or a Map.
typedef QuestionnaireAnswers = Map<String, dynamic>;

class QuestionOption {
  const QuestionOption(this.value, this.text);
  final String value;
  final Map<String, String> text;

  String label(String lang) => text[lang] ?? text['en'] ?? value;
}

/// `place` is a district / taluka / city, picked from places.json or typed.
enum QuestionType { single, multi, select, text, place, pair }

enum QuestionAudience { both, existing }

class QuestionField {
  const QuestionField({
    required this.id,
    required this.step,
    required this.audience,
    required this.type,
    required this.required,
    required this.question,
    this.essential = false,
    this.fromProfile = false,
    this.options = const [],
    this.exclusive = const [],
    this.parts = const [],
    this.placeholder = const {},
    this.place,
    this.stateField,
    this.districtField,
  });

  final String id;
  final int step;
  final QuestionAudience audience;
  final QuestionType type;
  final bool required;
  final Map<String, String> question;

  /// Part of the short survey a guest sees first.
  final bool essential;

  /// Answered by the personal details (gender, date of birth, home state / district).
  final bool fromProfile;
  final List<QuestionOption> options;

  /// Option keys that clear every other choice (e.g. "None").
  final List<String> exclusive;

  /// For `pair` fields: (part id, label by language).
  final List<(String, Map<String, String>)> parts;
  final Map<String, String> placeholder;

  /// For `place` fields: `district`, `taluka` or `city`, and the questions it depends on.
  final String? place;
  final String? stateField;
  final String? districtField;

  String questionText(String lang) => question[lang] ?? question['en'] ?? id;

  static Map<String, String> _texts(Map<String, dynamic> j) => {
    for (final l in questionnaireLanguages)
      if (j[l] is String) l: j[l] as String,
  };

  factory QuestionField.fromJson(Map<String, dynamic> j) => QuestionField(
    id: j['id'] as String,
    step: j['step'] as int,
    audience: QuestionAudience.values.byName(j['audience'] as String),
    type: QuestionType.values.byName(j['type'] as String),
    required: j['required'] == true,
    essential: j['essential'] == true,
    fromProfile: j['from_profile'] == true,
    question: _texts(j['question'] as Map<String, dynamic>),
    options: [
      for (final o in (j['options'] as List? ?? const []))
        QuestionOption(
          (o as Map<String, dynamic>)['value'] as String,
          _texts(o),
        ),
    ],
    exclusive: [
      for (final e in (j['exclusive'] as List? ?? const [])) e as String,
    ],
    parts: [
      for (final p in (j['parts'] as List? ?? const []))
        (
          (p as Map<String, dynamic>)['id'] as String,
          _texts(p['label'] as Map<String, dynamic>),
        ),
    ],
    placeholder: _texts((j['placeholder'] as Map<String, dynamic>?) ?? const {}),
    place: j['place'] as String?,
    stateField: j['state_field'] as String?,
    districtField: j['district_field'] as String?,
  );
}

class EligibilityQuestionnaire {
  const EligibilityQuestionnaire(this.fields);
  final List<QuestionField> fields;

  /// Option key for "Not started yet" in `business_age`.
  static const notStartedKey = 'not_started';

  /// Questions that must be answered before going on (same as `required` in the JSON).
  static const requiredIds = <String>[
    'gender',
    'age_band',
    'business_state',
    'nature',
    'business_age',
  ];

  static const stepCount = 6;

  factory EligibilityQuestionnaire.parse(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    return EligibilityQuestionnaire([
      for (final f in (j['fields'] as List))
        QuestionField.fromJson(f as Map<String, dynamic>),
    ]);
  }

  static Future<EligibilityQuestionnaire> load([AssetBundle? bundle]) async =>
      EligibilityQuestionnaire.parse(
        await (bundle ?? rootBundle).loadString(
          'assets/questionnaire/questionnaire.json',
        ),
      );

  static String _norm(String s) =>
      s.toLowerCase().replaceAll('&', 'and').replaceAll(RegExp('[^a-z]'), '');

  /// Answers the personal details already give, so they are not asked twice:
  /// gender, age band (from the date of birth), home state and district.
  QuestionnaireAnswers derive(UserProfile p) {
    final out = <String, dynamic>{};
    final g = p.gender.toLowerCase();
    if (g.isNotEmpty) {
      out['gender'] = g.startsWith('f')
          ? 'woman'
          : g.startsWith('m')
          ? 'man'
          : 'other';
    }
    final dob = p.dob;
    if (dob != null) {
      final age = DateTime.now().difference(dob).inDays ~/ 365.25;
      if (age >= 0 && age < 120) {
        out['age_band'] = age < 25
            ? 'under_25'
            : age <= 35
            ? 'a25_35'
            : age <= 45
            ? 'a36_45'
            : age <= 60
            ? 'a46_60'
            : 'over_60';
      }
    }
    if (p.state.trim().isNotEmpty) {
      final states = fields.firstWhere((f) => f.id == 'home_state').options;
      for (final o in states) {
        if (_norm(o.text['en'] ?? '') == _norm(p.state)) {
          out['home_state'] = o.value;
        }
      }
    }
    if (p.district.trim().isNotEmpty) out['home_district'] = p.district.trim();
    return out;
  }

  /// Questions for a running business appear once `business_age` says it has started.
  bool isVisible(QuestionField f, QuestionnaireAnswers a) {
    if (f.audience == QuestionAudience.both) return true;
    final age = a['business_age'];
    if (age is! String || age.isEmpty) return false;
    return age != notStartedKey;
  }

  /// Hidden because the personal details answer it.
  bool isHidden(QuestionField f, QuestionnaireAnswers derived) =>
      f.fromProfile && derived.containsKey(f.id);

  /// The questions this person is asked: [quick] (a guest's short survey) or all of them.
  List<QuestionField> asked(
    QuestionnaireAnswers a,
    QuestionnaireAnswers derived, {
    required bool quick,
  }) => [
    for (final f in fields)
      if (isVisible(f, a) && !isHidden(f, derived) && (!quick || f.essential))
        f,
  ];

  List<QuestionField> fieldsInStep(
    int step,
    QuestionnaireAnswers a,
    QuestionnaireAnswers derived, {
    required bool quick,
  }) => [
    for (final f in asked(a, derived, quick: quick))
      if (f.step == step) f,
  ];

  /// Steps that have at least one question, in order.
  List<int> visibleSteps(
    QuestionnaireAnswers a,
    QuestionnaireAnswers derived, {
    required bool quick,
  }) => [
    for (var s = 0; s < stepCount; s++)
      if (fieldsInStep(s, a, derived, quick: quick).isNotEmpty) s,
  ];

  static bool isEmpty(Object? v) {
    if (v == null) return true;
    if (v is String) return v.isEmpty;
    if (v is List) return v.isEmpty;
    if (v is Map) {
      return !v.values.any((x) => x != null && x != '');
    }
    return false;
  }

  /// True once the five required questions have an answer.
  static bool isComplete(QuestionnaireAnswers a) =>
      requiredIds.every((id) => !isEmpty(a[id]));

  static bool _answered(QuestionField f, Object? v) {
    if (isEmpty(v)) return false;
    if (f.type == QuestionType.pair) {
      return v is Map && v['total'] != null && v['women'] != null;
    }
    return true;
  }

  /// True once every question this person has to answer is answered:
  /// the guest's short list, or (Google sign-in) all of them.
  bool isDone(
    QuestionnaireAnswers saved,
    QuestionnaireAnswers derived, {
    required bool all,
  }) {
    final a = {...saved, ...derived};
    return asked(a, derived, quick: !all).every((f) => _answered(f, a[f.id]));
  }
}

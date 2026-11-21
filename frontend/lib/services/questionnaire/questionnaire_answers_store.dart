import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/questionnaire.dart';
import '../recommendation/indian_states.dart';
import 'questionnaire_repository.dart';

class QuestionnaireAnswersStore {
  QuestionnaireAnswersStore({
    QuestionnaireRepository? repository,
    Future<SharedPreferences> Function()? preferences,
  }) : _repository = repository ?? QuestionnaireRepository(),
       _preferences = preferences ?? SharedPreferences.getInstance;

  static const String preferencesKey = 'questionnaire_answers_v1';

  final QuestionnaireRepository _repository;
  final Future<SharedPreferences> Function() _preferences;

  Future<Map<String, Object?>> loadAnswers() async {
    final preferences = await _preferences();
    final raw = preferences.getString(preferencesKey);
    if (raw == null) return {};

    final envelope = jsonDecode(raw) as Map<String, dynamic>;
    final savedAnswers = Map<String, Object?>.from(envelope['answers'] as Map);
    final definition = await _repository.load();
    final validAnswers = <String, Object?>{};
    for (final entry in savedAnswers.entries) {
      final field = _field(definition, entry.key);
      if (field != null && isValidAnswer(field, entry.value)) {
        validAnswers[entry.key] = entry.value;
      }
    }

    if (envelope['schema_version'] != definition.schemaVersion ||
        validAnswers.length != savedAnswers.length) {
      await _write(preferences, definition, validAnswers);
    }
    return validAnswers;
  }

  Future<void> saveAnswer(String fieldId, Object? answer) async {
    await saveAnswers({fieldId: answer});
  }

  Future<void> saveAnswers(Map<String, Object?> updates) async {
    final definition = await _repository.load();
    final answers = await loadAnswers();
    for (final entry in updates.entries) {
      final field = _field(definition, entry.key);
      if (field == null || !isValidAnswer(field, entry.value)) {
        throw ArgumentError.value(
          entry.value,
          entry.key,
          'Invalid questionnaire answer',
        );
      }
      answers[entry.key] = entry.value;
    }
    await _write(await _preferences(), definition, answers);
  }

  Future<void> clearAnswer(String fieldId) async {
    final definition = await _repository.load();
    final answers = await loadAnswers();
    answers.remove(fieldId);
    await _write(await _preferences(), definition, answers);
  }

  Future<void> clearAfterUpload() async {
    await (await _preferences()).remove(preferencesKey);
  }

  Future<bool> hasAnswers() async => (await loadAnswers()).isNotEmpty;

  bool isValidAnswer(QuestionnaireField field, Object? answer) {
    final values = field.options.map((option) => option.value).toSet();
    switch (field.type) {
      case 'single_select':
        return answer is String && values.contains(answer);
      case 'multi_select':
        return answer is List &&
            answer.every(
              (value) => value is String && values.contains(value),
            ) &&
            answer.toSet().length == answer.length;
      case 'boolean':
        return answer is bool;
      case 'boolean_with_district':
        if (answer is! Map ||
            answer['resident'] is! bool ||
            answer['district'] is! String) {
          return false;
        }
        return answer['resident'] as bool ||
            (answer['district'] as String).trim().isNotEmpty;
      case 'location':
        if (answer is! Map ||
            answer['area'] is! String ||
            answer['district'] is! String ||
            answer['taluka'] is! String) {
          return false;
        }
        return values.contains(answer['area']) &&
            (answer['district'] as String).trim().isNotEmpty &&
            (answer['taluka'] as String).trim().isNotEmpty;
      case 'number':
        final min = field.answerRules['min'] as int?;
        final max = field.answerRules['max'] as int?;
        return answer is int &&
            (min == null || answer >= min) &&
            (max == null || answer <= max);
      case 'number_pair':
        return answer is Map &&
            answer['total'] is int &&
            answer['women'] is int &&
            (answer['total'] as int) >= 0 &&
            (answer['women'] as int) >= 0 &&
            (answer['women'] as int) <= (answer['total'] as int);
      case 'text_tags':
        return answer is List &&
            answer.isNotEmpty &&
            answer.every((value) => value is String && value.trim().isNotEmpty);
      case 'state':
        return answer is String &&
            IndianStates.names.contains(IndianStates.canonical(answer));
      default:
        return false;
    }
  }

  QuestionnaireField? _field(QuestionnaireDefinition definition, String id) {
    for (final field in definition.allFields) {
      if (field.id == id) return field;
    }
    return null;
  }

  Future<void> _write(
    SharedPreferences preferences,
    QuestionnaireDefinition definition,
    Map<String, Object?> answers,
  ) async {
    final saved = await preferences.setString(
      preferencesKey,
      jsonEncode({
        'schema_version': definition.schemaVersion,
        'answers': answers,
      }),
    );
    if (!saved) throw StateError('Questionnaire answer was not saved');
  }
}

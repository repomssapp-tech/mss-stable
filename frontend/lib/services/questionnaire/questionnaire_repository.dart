import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/questionnaire.dart';

class QuestionnaireRepository {
  static const String assetPath = 'assets/data/questionnaire.json';
  static const String displayAssetPath =
      'assets/data/questionnaire_display.json';

  Future<QuestionnaireDefinition>? _definition;

  Future<QuestionnaireDefinition> load() => _definition ??= _loadDefinition();

  Future<QuestionnaireDefinition> _loadDefinition() async {
    final sources = await Future.wait([
      rootBundle.loadString(assetPath),
      rootBundle.loadString(displayAssetPath),
    ]);
    final schema = jsonDecode(sources[0]) as Map<String, dynamic>;
    final display = jsonDecode(sources[1]) as Map<String, dynamic>;
    for (final field
        in (schema['fields'] as List).cast<Map<String, dynamic>>()) {
      final copy = display[field['id']] as Map<String, dynamic>?;
      if (copy == null) continue;
      (field['question'] as Map<String, dynamic>).addAll(
        copy['question'] as Map<String, dynamic>,
      );
      final optionLabels = copy['options'] as Map<String, dynamic>;
      for (final option
          in (field['options'] as List).cast<Map<String, dynamic>>()) {
        final labels = optionLabels[option['value']] as Map<String, dynamic>?;
        if (labels != null) option.addAll(labels);
      }
    }
    return QuestionnaireDefinition.fromJson(schema);
  }
}

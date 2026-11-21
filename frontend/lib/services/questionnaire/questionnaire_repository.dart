import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/questionnaire.dart';

class QuestionnaireRepository {
  static const String assetPath = 'assets/data/questionnaire.json';

  Future<QuestionnaireDefinition>? _definition;

  Future<QuestionnaireDefinition> load() => _definition ??= _loadDefinition();

  Future<QuestionnaireDefinition> _loadDefinition() async {
    final source = await rootBundle.loadString(assetPath);
    final json = jsonDecode(source) as Map<String, dynamic>;
    return QuestionnaireDefinition.fromJson(json);
  }
}

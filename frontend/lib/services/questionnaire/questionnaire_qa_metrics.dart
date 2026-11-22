import 'dart:convert';

import 'package:flutter/foundation.dart';

class QuestionnaireQaMetrics {
  static const enabled =
      kDebugMode && bool.fromEnvironment('SMART_ASSESSMENT_QA');

  final _fields = <String, bool?>{};
  String? _lastField;
  bool completed = false;

  void showField(String fieldId) {
    _lastField = fieldId;
    _fields.putIfAbsent(fieldId, () => null);
  }

  void advance(String fieldId, {required bool answered}) {
    _fields[fieldId] = answered;
  }

  void reportRun() {
    if (_fields.isEmpty) return;
    emit('run', {
      'fields': _fields,
      'completed': completed,
      if (!completed) 'drop_off_field': _lastField,
    });
  }

  static void emit(String event, Map<String, Object?> properties) {
    if (!enabled) return;
    final payload = jsonEncode({'event': event, ...properties});
    debugPrint('SMART_ASSESSMENT_QA $payload');
  }
}

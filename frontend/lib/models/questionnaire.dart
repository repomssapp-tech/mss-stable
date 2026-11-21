class QuestionnaireOption {
  const QuestionnaireOption({
    required this.value,
    required this.labels,
    this.booleanAnswer,
  });

  final String value;
  final Map<String, String> labels;
  final bool? booleanAnswer;

  String labelFor(String language) => labels[language] ?? labels['en'] ?? value;

  factory QuestionnaireOption.fromJson(Map<String, dynamic> json) {
    return QuestionnaireOption(
      value: json['value'] as String,
      labels: _localizedStrings(json),
      booleanAnswer: json['answer'] as bool?,
    );
  }
}

class QuestionnairePart {
  const QuestionnairePart({required this.key, required this.labels});

  final String key;
  final Map<String, String> labels;

  String labelFor(String language) => labels[language] ?? labels['en'] ?? key;

  factory QuestionnairePart.fromJson(Map<String, dynamic> json) {
    return QuestionnairePart(
      key: json['key'] as String,
      labels: _localizedStrings(json['label'] as Map<String, dynamic>),
    );
  }
}

class QuestionnaireField {
  const QuestionnaireField({
    required this.id,
    required this.type,
    required this.requiredFor,
    required this.question,
    required this.hints,
    required this.options,
    required this.parts,
    required this.answerRules,
    required this.subInput,
  });

  final String id;
  final String type;
  final String requiredFor;
  final Map<String, String> question;
  final Map<String, String> hints;
  final List<QuestionnaireOption> options;
  final List<QuestionnairePart> parts;
  final Map<String, dynamic> answerRules;
  final Map<String, dynamic>? subInput;

  String questionFor(String language) =>
      question[language] ?? question['en'] ?? id;

  String subInputLabelFor(String language) {
    final label = subInput?['label'];
    if (label is! Map<String, dynamic>) return '';
    return label[language] as String? ?? label['en'] as String? ?? '';
  }

  factory QuestionnaireField.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    final rawParts = json['parts'] as List<dynamic>? ?? const [];
    return QuestionnaireField(
      id: json['id'] as String,
      type: json['type'] as String,
      requiredFor: json['required_for'] as String? ?? 'both',
      question: _localizedStrings(json['question'] as Map<String, dynamic>),
      hints: _localizedStrings(
        json['hint'] as Map<String, dynamic>? ?? const {},
      ),
      options: rawOptions
          .map(
            (option) => QuestionnaireOption.fromJson(
              Map<String, dynamic>.from(option as Map),
            ),
          )
          .toList(growable: false),
      parts: rawParts
          .map(
            (part) => QuestionnairePart.fromJson(
              Map<String, dynamic>.from(part as Map),
            ),
          )
          .toList(growable: false),
      answerRules: Map<String, dynamic>.from(
        json['answer'] as Map<String, dynamic>? ?? const {},
      ),
      subInput: json['sub_input'] == null
          ? null
          : Map<String, dynamic>.from(json['sub_input'] as Map),
    );
  }
}

class QuestionnaireDefinition {
  const QuestionnaireDefinition({
    required this.schemaVersion,
    required this.fields,
    required this.generalFields,
  });

  final String schemaVersion;
  final List<QuestionnaireField> fields;
  final List<QuestionnaireField> generalFields;

  List<QuestionnaireField> get allFields => [...fields, ...generalFields];

  factory QuestionnaireDefinition.fromJson(Map<String, dynamic> json) {
    final general = json['scopes']?['general'];
    final generalFields = general is Map<String, dynamic>
        ? (general['fields'] as List<dynamic>? ?? const [])
              .map(
                (field) => QuestionnaireField.fromJson(
                  Map<String, dynamic>.from(field as Map),
                ),
              )
              .toList(growable: false)
        : const <QuestionnaireField>[];

    return QuestionnaireDefinition(
      schemaVersion: json['schema_version'] as String,
      fields: (json['fields'] as List<dynamic>)
          .map(
            (field) => QuestionnaireField.fromJson(
              Map<String, dynamic>.from(field as Map),
            ),
          )
          .toList(growable: false),
      generalFields: generalFields,
    );
  }
}

Map<String, String> _localizedStrings(Map<String, dynamic> json) => {
  for (final language in const ['en', 'mr', 'hi', 'ta'])
    if (json[language] is String) language: json[language] as String,
};

import '../../services/catalog/centralized_translator.dart';

/// Questionnaire node model supporting 3-tier localization:
/// Priority 1: Direct Tamil fields (questionTextTa, optionsTa, subtitleTextTa)
/// Priority 2: CentralizedTranslator fallback
/// Priority 3: English default
///
/// Extracted verbatim from `smart_assessment_bottom_sheet.dart` (frontend
/// refactor C5, safe slice) — a plain data class + its localization method,
/// with zero coupling to `_SmartAssessmentBottomSheetState`.
class QuestionNode {
  final String id;
  final String questionText;
  final String? questionTextTa;
  final String? subtitleText;
  final String? subtitleTextTa;
  final List<String> options;
  final List<String>? optionsTa;
  final String? Function(String selectedOption)? nextId;

  const QuestionNode({
    required this.id,
    required this.questionText,
    this.questionTextTa,
    this.subtitleText,
    this.subtitleTextTa,
    required this.options,
    this.optionsTa,
    this.nextId,
  });

  LocalizedQuestionNode toLocalized(String language) {
    final isTamil = language == 'ta';

    final String qText = isTamil
        ? ((questionTextTa != null && questionTextTa!.trim().isNotEmpty)
              ? questionTextTa!
              : CentralizedTranslator.instance.translate(questionText))
        : questionText;

    String? subText;
    if (subtitleText != null) {
      subText = isTamil
          ? ((subtitleTextTa != null && subtitleTextTa!.trim().isNotEmpty)
                ? subtitleTextTa!
                : CentralizedTranslator.instance.translate(subtitleText!))
          : subtitleText;
    }

    final List<String> locOptions = [];
    for (int i = 0; i < options.length; i++) {
      final rawOpt = options[i];
      if (isTamil) {
        if (optionsTa != null &&
            i < optionsTa!.length &&
            optionsTa![i].trim().isNotEmpty) {
          locOptions.add(optionsTa![i]);
        } else {
          locOptions.add(CentralizedTranslator.instance.translate(rawOpt));
        }
      } else {
        locOptions.add(rawOpt);
      }
    }

    return LocalizedQuestionNode(
      id: id,
      questionText: qText,
      subtitleText: subText,
      options: List.unmodifiable(locOptions),
      rawNode: this,
    );
  }
}

/// Pre-localized questionnaire node for UI rendering.
class LocalizedQuestionNode {
  final String id;
  final String questionText;
  final String? subtitleText;
  final List<String> options;
  final QuestionNode rawNode;

  const LocalizedQuestionNode({
    required this.id,
    required this.questionText,
    this.subtitleText,
    required this.options,
    required this.rawNode,
  });

  String? nextId(String selectedLocalizedOption) {
    final index = options.indexOf(selectedLocalizedOption);
    final rawOption = (index >= 0 && index < rawNode.options.length)
        ? rawNode.options[index]
        : selectedLocalizedOption;
    return rawNode.nextId?.call(rawOption);
  }
}

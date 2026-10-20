// The state-specific questionnaire interpolates the user's state into a Tamil
// sentence; that name must be the Tamil one, never the raw English tag.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations_en.dart';
import 'package:frontend/l10n/app_localizations_ta.dart';
import 'package:frontend/widgets/assistant/smart_assessment/assessment_question_flows.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Tamil state questions use the Tamil state name', () {
    final flow = getStateFlow(
      'Maharashtra',
      AppLocalizationsEn(),
      AppLocalizationsTa(),
    );
    for (final id in ['state_q1', 'state_q2', 'state_q3']) {
      final ta = flow[id]!.questionTextTa;
      expect(ta, contains('மகாராஷ்டிரா'), reason: id);
      expect(ta, isNot(contains('Maharashtra')), reason: id);
    }
  });

  test('English questions keep the English state name', () {
    final flow = getStateFlow(
      'Maharashtra',
      AppLocalizationsEn(),
      AppLocalizationsTa(),
    );
    expect(flow['state_q1']!.questionText, contains('Maharashtra'));
  });

  test('the Tamil residency question uses a proper word for "resident"', () {
    final flow = getStateFlow(
      'Kerala',
      AppLocalizationsEn(),
      AppLocalizationsTa(),
    );
    expect(flow['state_q1']!.questionTextTa, contains('குடியிருப்பாளரா'));
  });
}

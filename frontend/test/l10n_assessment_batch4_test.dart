// Batch 4 of the custom string-map -> gen-l10n ARB migration.
//
// `smart_assessment_bottom_sheet.dart` used to carry an embedded bilingual
// question/answer bank (`QuestionNode.questionTextTa` / `optionsTa` literals)
// plus inline `isTamil ? '...' : '...'` UI labels. The bank is now built by
// `_getXxxFlow(AppLocalizations en, AppLocalizations ta)` from ARB keys
// (`assessEduQ1`, `assessEduQ1Opt1`, ... `assessStepLabel`,
// `assessSkipToResults`, reused `back` / `close`).
//
// Execution test: pump the sheet under a real `MaterialApp` locale and assert,
// via `find.text`, that the first question, an option label, and the
// back / skip-to-results labels render from `AppLocalizations` for the active
// locale (Tamil under `ta`, English under `en`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/widgets/assistant/smart_assessment_bottom_sheet.dart';

// Exact values that used to be hardcoded in smart_assessment_bottom_sheet.dart.
// Education flow, first question (edu_q1) + its first option.
const _eduQ1En = 'What is your current level of education?';
const _eduQ1Ta = 'உங்கள் தற்போதைய கல்வித் தகுதி என்ன?';
const _eduQ1Opt1En = 'Schooling (Up to 12th)';
const _eduQ1Opt1Ta = 'பள்ளி கல்வி (12 ஆம் வகுப்பு வரை)';
// Second question reached after picking the "Schooling" option (edu_q2_school).
const _eduQ2SchoolTa = 'நீங்கள் தற்போது எந்த வகுப்பில் படிக்கிறீர்கள்?';

// Inline UI labels.
const _backEn = 'Back';
const _backTa = 'பின்செல்'; // reused `back` key
const _skipEn = 'Skip to Results';
const _skipTa = 'முடிவுகளுக்குச் செல்'; // assessSkipToResults key

// Seed the mocked SharedPreferences so `AppProvider._loadState()` (kicked off
// from the constructor) restores the same locale we pump the `MaterialApp`
// with -- otherwise its async read resets `selectedLanguage` to 'en' mid-test.
void _seedLocale(Locale locale) {
  SharedPreferences.setMockInitialValues({'language': locale.languageCode});
}

Widget _host(Locale locale) {
  return ChangeNotifierProvider<AppProvider>(
    create: (_) => AppProvider()..changeLanguage(locale.languageCode),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SmartAssessmentBottomSheet(
          cardTitle: 'Education',
          cardType: 'category',
          onCompleted: () {},
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Tamil locale: first question, option, back/skip labels from ARB',
    (tester) async {
      _seedLocale(const Locale('ta'));
      await tester.pumpWidget(_host(const Locale('ta')));
      await tester.pumpAndSettle();

      // First question + its first option render in Tamil.
      expect(find.text(_eduQ1Ta), findsOneWidget);
      expect(find.text(_eduQ1Opt1Ta), findsOneWidget);
      expect(find.text(_eduQ1En), findsNothing);
      expect(find.text(_eduQ1Opt1En), findsNothing);

      // Skip-to-results label (always visible) renders in Tamil.
      expect(find.text(_skipTa), findsOneWidget);
      expect(find.text(_skipEn), findsNothing);

      // Advance to the second question; the Back label then appears in Tamil.
      await tester.tap(find.text(_eduQ1Opt1Ta));
      await tester.pumpAndSettle();

      expect(find.text(_eduQ2SchoolTa), findsOneWidget);
      expect(find.text(_backTa), findsOneWidget);
      expect(find.text(_backEn), findsNothing);
    },
  );

  testWidgets(
    'English locale: first question, option, back/skip labels from ARB',
    (tester) async {
      _seedLocale(const Locale('en'));
      await tester.pumpWidget(_host(const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text(_eduQ1En), findsOneWidget);
      expect(find.text(_eduQ1Opt1En), findsOneWidget);
      expect(find.text(_eduQ1Ta), findsNothing);
      expect(find.text(_eduQ1Opt1Ta), findsNothing);

      expect(find.text(_skipEn), findsOneWidget);
      expect(find.text(_skipTa), findsNothing);

      await tester.tap(find.text(_eduQ1Opt1En));
      await tester.pumpAndSettle();

      // Second question (edu_q2_school) in English + Back label.
      expect(
        find.text('What class/grade are you currently enrolled in?'),
        findsOneWidget,
      );
      expect(find.text(_backEn), findsOneWidget);
      expect(find.text(_backTa), findsNothing);
    },
  );
}

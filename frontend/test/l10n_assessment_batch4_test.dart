import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/widgets/assistant/smart_assessment_bottom_sheet.dart';

import 'questionnaire_widget_test_assets.dart';

Widget _host(Locale locale) {
  return ChangeNotifierProvider<AppProvider>(
    create: (_) => AppProvider()..changeLanguage(locale.languageCode),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SmartAssessmentBottomSheet(
          cardTitle: 'Education & Fellowship',
          cardType: 'category',
          onCompleted: () {},
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useQuestionnaireWidgetAssets();

  const enQuestion = 'What is your highest level of education?';
  const taQuestion = 'நீங்கள் முடித்த உயர்ந்த கல்வி நிலை எது?';
  const enOption = 'Below 7th Pass';
  const taOption = '7 ஆம் வகுப்புக்குக் கீழ்';

  for (final language in ['ta', 'en']) {
    testWidgets(
      '$language assessment localizes questions, options and controls',
      (tester) async {
        final isTamil = language == 'ta';
        SharedPreferences.setMockInitialValues({'language': language});
        await tester.pumpWidget(_host(Locale(language)));
        await tester.pumpAndSettle();

        final sheet = tester.element(find.byType(SmartAssessmentBottomSheet));
        final l10n = AppLocalizations.of(sheet)!;
        final option = isTamil ? taOption : enOption;
        expect(find.text(isTamil ? taQuestion : enQuestion), findsOneWidget);
        expect(find.text(isTamil ? enQuestion : taQuestion), findsNothing);
        expect(find.text(option), findsOneWidget);
        expect(find.text(isTamil ? enOption : taOption), findsNothing);
        expect(find.text(l10n.assessSkipToResults), findsOneWidget);

        await tester.tap(find.text(option));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.next));
        await tester.pumpAndSettle();

        expect(
          find.text(isTamil ? 'சமூகம் / பிரிவு' : 'Community / Category'),
          findsOneWidget,
        );
        expect(find.text(l10n.back), findsOneWidget);
      },
    );
  }
}

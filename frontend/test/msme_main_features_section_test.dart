import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/screens/regular_mode/msme/msme_main_features_section.dart';

void main() {
  Widget buildTestWidget(String moduleId) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ta')],
      home: Scaffold(
        body: MsmeMainFeaturesSection(
          moduleId: moduleId,
          iconColor: const Color(0xFF2563EB),
        ),
      ),
    );
  }

  group('MsmeMainFeaturesSection (MS1/MS2)', () {
    testWidgets(
      'schemes module no longer claims deadline reminders or '
      'side-by-side comparison, but keeps the real save claim',
      (tester) async {
        await tester.pumpWidget(buildTestWidget('schemes'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Reminders for registration'), findsNothing);
        expect(find.textContaining('side-by-side comparison'), findsNothing);
        expect(find.text('Save schemes for later'), findsOneWidget);
      },
    );

    testWidgets(
      'tax_gst module keeps the late-payment calculator claim '
      '(verified real: a live calculator exists)',
      (tester) async {
        await tester.pumpWidget(buildTestWidget('tax_gst'));
        await tester.pumpAndSettle();

        expect(
          find.text('Late payment interest claim calculator (3x Bank Rate)'),
          findsOneWidget,
        );
      },
    );
  });
}

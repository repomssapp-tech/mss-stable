import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/screens/regular_mode/categories/dpiit_checklist_sheet.dart';
import 'package:frontend/screens/regular_mode/categories/dpiit_eligibility.dart';

void main() {
  test('every criterion must be met; unmet ones are listed in order', () {
    expect(unmetDpiitCriteria(DpiitCriterion.values.toSet()), isEmpty);
    expect(unmetDpiitCriteria({}), DpiitCriterion.values);
    expect(
      unmetDpiitCriteria(
        DpiitCriterion.values.toSet()..remove(DpiitCriterion.notReconstruction),
      ),
      [DpiitCriterion.notReconstruction],
    );
  });

  group('checklist sheet', () {
    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDpiitChecklistSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows five criteria and names the unmet ones', (tester) async {
      await open(tester);
      expect(find.byType(CheckboxListTile), findsNWidgets(5));

      final boxes = find.byType(CheckboxListTile);
      for (var i = 0; i < 4; i++) {
        await tester.ensureVisible(boxes.at(i));
        await tester.tap(boxes.at(i));
        await tester.pump();
      }
      await tester.ensureVisible(find.text('Check Eligibility'));
      await tester.tap(find.text('Check Eligibility'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.textContaining('Not met: Working towards'), findsOneWidget);
    });

    testWidgets('all criteria met shows a check, and editing clears it', (
      tester,
    ) async {
      await open(tester);
      final boxes = find.byType(CheckboxListTile);
      for (var i = 0; i < 5; i++) {
        await tester.ensureVisible(boxes.at(i));
        await tester.tap(boxes.at(i));
        await tester.pump();
      }
      await tester.ensureVisible(find.text('Check Eligibility'));
      await tester.tap(find.text('Check Eligibility'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);

      await tester.ensureVisible(boxes.at(0));
      await tester.tap(boxes.at(0));
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/screens/regular_mode/categories/document_checklist_sheet.dart';

Widget _host({Locale locale = const Locale('en'), Widget? child}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body:
          child ??
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDocumentChecklistSheet(context),
              child: const Text('Open Sheet'),
            ),
          ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentChecklistSheet Widget Tests', () {
    testWidgets('renders default Private Limited checklist with 0/6 progress', (
      tester,
    ) async {
      await tester.pumpWidget(_host(child: const DocumentChecklistSheet()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('doc-checklist-sheet')), findsOneWidget);
      expect(find.text('Setup Document Checklist'), findsOneWidget);
      expect(find.text('0 / 6'), findsOneWidget);

      final progressFinder = find.byKey(const Key('doc-progress-indicator'));
      expect(progressFinder, findsOneWidget);
      final progressWidget = tester.widget<LinearProgressIndicator>(
        progressFinder,
      );
      expect(progressWidget.value, 0.0);

      // Verify initial 6 documents exist
      expect(find.byKey(const Key('doc-checklist-item-0')), findsOneWidget);
      expect(find.byKey(const Key('doc-checklist-item-5')), findsOneWidget);
      expect(find.text('Digital Signature Certificate (DSC)'), findsOneWidget);
    });

    testWidgets(
      'toggling items updates progress counter, bar and strikethrough',
      (tester) async {
        await tester.pumpWidget(_host(child: const DocumentChecklistSheet()));
        await tester.pumpAndSettle();

        expect(find.text('0 / 6'), findsOneWidget);

        // Tap first item
        await tester.tap(find.byKey(const Key('doc-checklist-item-0')));
        await tester.pumpAndSettle();

        expect(find.text('1 / 6'), findsOneWidget);
        var progress = tester.widget<LinearProgressIndicator>(
          find.byKey(const Key('doc-progress-indicator')),
        );
        expect(progress.value, closeTo(1 / 6, 0.001));

        // Tap second item
        await tester.tap(find.byKey(const Key('doc-checklist-item-1')));
        await tester.pumpAndSettle();

        expect(find.text('2 / 6'), findsOneWidget);

        // Untap first item
        await tester.tap(find.byKey(const Key('doc-checklist-item-0')));
        await tester.pumpAndSettle();

        expect(find.text('1 / 6'), findsOneWidget);
      },
    );

    testWidgets('switching entity type updates checklist items', (
      tester,
    ) async {
      await tester.pumpWidget(_host(child: const DocumentChecklistSheet()));
      await tester.pumpAndSettle();

      // Open dropdown
      await tester.tap(find.byKey(const Key('doc-entity-type-dropdown')));
      await tester.pumpAndSettle();

      // Select Partnership
      await tester.tap(find.text('Partnership').last);
      await tester.pumpAndSettle();

      // Partnership has 5 items
      expect(find.text('0 / 5'), findsOneWidget);
      expect(find.text('Partnership Deed drafting'), findsOneWidget);
      expect(find.text('Deed Registration with Registrar'), findsOneWidget);

      // Switch to LLP
      await tester.tap(find.byKey(const Key('doc-entity-type-dropdown')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('LLP').last);
      await tester.pumpAndSettle();

      expect(find.text('0 / 5'), findsOneWidget);
      expect(find.text('LLP Name Approval (RUN-LLP)'), findsOneWidget);
      expect(find.text('FiLLiP Form (LLP Incorporation)'), findsOneWidget);
    });

    testWidgets('copy button copies formatted checklist to clipboard', (
      tester,
    ) async {
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copiedText =
                (methodCall.arguments as Map<dynamic, dynamic>)['text']
                    as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.pumpWidget(_host(child: const DocumentChecklistSheet()));
      await tester.pumpAndSettle();

      // Check first item
      await tester.tap(find.byKey(const Key('doc-checklist-item-0')));
      await tester.pumpAndSettle();

      // Tap copy
      await tester.tap(find.byKey(const Key('doc-checklist-copy-btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify clipboard content
      expect(copiedText, isNotNull);
      expect(copiedText, contains('📋'));
      expect(copiedText, contains('[✓] Digital Signature Certificate (DSC)'));
      expect(copiedText, contains('[ ] Director Identification Number (DIN)'));

      // Verify feedback snackbar/toast
      expect(find.text('Results copied to clipboard'), findsOneWidget);

      // Drain remaining timers
      await tester.pumpAndSettle();
    });

    testWidgets('supports custom initialEntityType constructor parameter', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(child: const DocumentChecklistSheet(initialEntityType: 'LLP')),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 / 5'), findsOneWidget);
      expect(find.text('LLP Name Approval (RUN-LLP)'), findsOneWidget);
      expect(find.text('FiLLiP Form (LLP Incorporation)'), findsOneWidget);
    });

    testWidgets(
      'showDocumentChecklistSheet opens and closes via close button',
      (tester) async {
        await tester.pumpWidget(_host());
        await tester.pumpAndSettle();

        // Not open yet
        expect(find.byKey(const Key('doc-checklist-sheet')), findsNothing);

        // Open via launcher
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('doc-checklist-sheet')), findsOneWidget);

        // Dismiss via bottom button
        await tester.tap(find.byKey(const Key('doc-close-button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('doc-checklist-sheet')), findsNothing);
      },
    );

    testWidgets('close icon button in header dismisses sheet', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('doc-checklist-sheet')), findsOneWidget);

      // Dismiss via header close icon
      await tester.tap(find.byKey(const Key('doc-checklist-close-btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('doc-checklist-sheet')), findsNothing);
    });

    testWidgets('renders properly under Tamil locale', (tester) async {
      await tester.pumpWidget(
        _host(
          locale: const Locale('ta'),
          child: const DocumentChecklistSheet(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('doc-checklist-sheet')), findsOneWidget);
      expect(find.text('அமைப்பு ஆவணப் பட்டியல்'), findsOneWidget);
      expect(find.text('மின்னணு கையொப்பச் சான்றிதழ் (DSC)'), findsOneWidget);
      expect(find.text('0 / 6'), findsOneWidget);
    });
  });
}

// AppToast draws in the root Overlay, so a toast raised from inside a modal
// bottom sheet or dialog sits ON TOP of it. It used to be a SnackBar from the
// app's ScaffoldMessenger, which renders under modal routes: the feedback
// sheet's "too short" warning appeared behind the sheet.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/screens/regular_mode/help_support/help_feedback_bottom_sheet.dart';
import 'package:frontend/widgets/common/app_toast.dart';

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

/// A page with a button that opens a modal bottom sheet; the sheet's button
/// shows a warning toast from the sheet's own context.
Widget _sheetHost({VoidCallback? onAction}) => _app(
  Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (sheetContext) => SizedBox(
              height: 600,
              child: Center(
                child: TextButton(
                  onPressed: () => AppToast.showWarning(
                    sheetContext,
                    'Too short',
                    actionLabel: onAction == null ? null : 'Fix',
                    onAction: onAction,
                  ),
                  child: const Text('submit'),
                ),
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

void main() {
  tearDown(AppToast.hide);

  testWidgets('a toast shown from a modal bottom sheet is drawn above it', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(_sheetHost(onAction: () => tapped++));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('submit'));
    await tester.pumpAndSettle();

    // Visible and hit-testable: nothing (sheet, barrier) covers it.
    expect(find.text('Too short').hitTestable(), findsOneWidget);
    // Its action receives the tap, so it really is on top of the sheet.
    await tester.tap(find.text('Fix'));
    await tester.pumpAndSettle();
    expect(tapped, 1);
    // The sheet stays open underneath.
    expect(find.text('submit'), findsOneWidget);
  });

  testWidgets('a page toast raised while a sheet covers the page is on top', (
    tester,
  ) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) {
              pageContext = context;
              return TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) =>
                      const SizedBox(height: 600, child: Text('sheet')),
                ),
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // E.g. an async page callback finishing while the sheet is open.
    AppToast.showInfo(pageContext, 'Saved');
    await tester.pumpAndSettle();
    expect(find.text('Saved').hitTestable(), findsOneWidget);
  });

  testWidgets('on a plain page the toast stays clear of the bottom bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => AppToast.showSuccess(context, 'Bookmarked'),
              child: const Text('save'),
            ),
          ),
          bottomNavigationBar: const SizedBox(
            height: 80,
            child: Text('nav bar'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();
    expect(find.text('Bookmarked').hitTestable(), findsOneWidget);
    expect(
      tester.getRect(find.text('Bookmarked')).bottom,
      lessThanOrEqualTo(tester.getRect(find.text('nav bar')).top),
    );
    expect(find.text('nav bar').hitTestable(), findsOneWidget);
  });

  testWidgets('a toast shown from a dialog is drawn above it', (tester) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  content: TextButton(
                    onPressed: () =>
                        AppToast.showError(dialogContext, 'Wrong password'),
                    child: const Text('check'),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('check'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong password').hitTestable(), findsOneWidget);
  });

  testWidgets('toasts replace each other and leave after their duration', (
    tester,
  ) async {
    await tester.pumpWidget(_sheetHost());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('submit'));
    await tester.pump();
    await tester.tap(find.text('submit'));
    await tester.pumpAndSettle();
    expect(find.text('Too short'), findsOneWidget); // replaced, not stacked

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Too short'), findsNothing);
    expect(find.text('submit'), findsOneWidget); // sheet untouched
  });

  testWidgets('the toast is a live region for screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_sheetHost());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('submit'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Too short')),
      matchesSemantics(label: 'Too short', isLiveRegion: true),
    );
    semantics.dispose();
  });

  testWidgets('the toast stays above the keyboard', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(_sheetHost());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('submit'));
    await tester.pumpAndSettle();
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final keyboardTop = screen.height - 900 / tester.view.devicePixelRatio;
    expect(
      tester.getRect(find.text('Too short')).bottom,
      lessThan(keyboardTop),
    );
  });

  for (final (locale, expected) in const [
    (Locale('en'), 'Please add a bit more detail (at least 10 characters).'),
    (Locale('hi'), 'कृपया थोड़ा और विवरण लिखें (कम से कम 10 अक्षर)।'),
    (
      Locale('ta'),
      'இன்னும் சற்று விவரம் சேர்க்கவும் (குறைந்தது 10 எழுத்துகள்).',
    ),
  ]) {
    testWidgets('feedback sheet: the too-short warning is localized and on top '
        '(${locale.languageCode})', (tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showFeedbackBottomSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
          locale: locale,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'name@example.com');
      await tester.enterText(fields.at(1), 'too short');
      final l10n = lookupAppLocalizations(locale);
      await tester.ensureVisible(find.text(l10n.helpSubmitFeedback));
      await tester.tap(find.text(l10n.helpSubmitFeedback));
      await tester.pumpAndSettle();

      expect(find.text(expected).hitTestable(), findsOneWidget);
      // Still on the sheet: nothing was submitted.
      expect(find.text(l10n.helpSubmitFeedback), findsOneWidget);
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/companion_mode/assisted_profile/step1_state_selector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        publishableKey: 'test-publishable-key',
      );
    } catch (_) {}
  });

  Widget buildTestWidget({
    required String selectedState,
    required ValueChanged<String> onStateSelected,
  }) {
    return ChangeNotifierProvider<AppProvider>(
      create: (_) => AppProvider(),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ta')],
        home: Scaffold(
          body: Step1StateSelector(
            selectedState: selectedState,
            onStateSelected: onStateSelected,
          ),
        ),
      ),
    );
  }

  group('Step1StateSelector - "Other" picker (AS1)', () {
    testWidgets(
      'tapping "Other" opens a searchable picker, and selecting a state '
      'from it calls onStateSelected with that real state name, never '
      'the literal "Other"',
      (tester) async {
        String? selected;

        await tester.pumpWidget(
          buildTestWidget(
            selectedState: '',
            onStateSelected: (v) => selected = v,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Other States'));
        await tester.pumpAndSettle();

        // The picker is open with a search field -- not an immediate
        // onStateSelected('Other') call.
        expect(selected, isNull);
        expect(find.byType(TextField), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'Kerala');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ListTile, 'Kerala'));
        await tester.pumpAndSettle();

        expect(selected, equals('Kerala'));
        expect(selected, isNot(equals('Other')));
      },
    );

    testWidgets(
      'the search field filters the full state/UT list, not just the 5 '
      'quick-pick states',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(selectedState: '', onStateSelected: (_) {}),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Other States'));
        await tester.pumpAndSettle();

        // Sikkim is not one of the 5 quick-pick cards (Tamil Nadu,
        // Maharashtra, Uttar Pradesh, Karnataka, Gujarat), so finding it
        // here proves the picker searches the full canonical list.
        await tester.enterText(find.byType(TextField), 'Sikkim');
        await tester.pumpAndSettle();

        expect(find.widgetWithText(ListTile, 'Sikkim'), findsOneWidget);
      },
    );
  });
}

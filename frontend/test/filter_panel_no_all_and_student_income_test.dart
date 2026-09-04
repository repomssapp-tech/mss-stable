import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/widgets/filter_panel.dart';
import 'package:frontend/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  group('FilterPanel Ministry, Department, and Annual Income Options', () {
    testWidgets('Ministry and Department do not contain "All" and default to unset',
        (WidgetTester tester) async {
      final provider = AppProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: FilterPanel(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Select Ministry" and "Select Department" placeholder texts should be visible
      expect(find.text('Select Ministry'), findsWidgets);
      expect(find.text('Select Department'), findsWidgets);

      // Find all DropdownButtons
      final dropdowns = tester.widgetList<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      ).toList();

      // Find Ministry dropdown
      final ministryDropdown = dropdowns.firstWhere((d) {
        return d.items?.any((item) =>
                item.value == 'Ministry of MSME' ||
                item.value == 'Ministry of Education') ==
            true;
      });
      final ministryItemValues =
          ministryDropdown.items?.map((item) => item.value).toList() ?? [];
      expect(ministryItemValues.contains('All'), isFalse,
          reason: 'Ministry dropdown must not contain "All"');
      expect(ministryDropdown.value, isNull,
          reason: 'Ministry must not have any item selected by default');

      // Find Department dropdown
      final deptDropdown = dropdowns.firstWhere((d) {
        return d.items?.any((item) =>
                item.value == 'Dept of MSME Development' ||
                item.value == 'Dept of Higher Education') ==
            true;
      });
      final deptItemValues =
          deptDropdown.items?.map((item) => item.value).toList() ?? [];
      expect(deptItemValues.contains('All'), isFalse,
          reason: 'Department dropdown must not contain "All"');
      expect(deptDropdown.value, isNull,
          reason: 'Department must not have any item selected by default');

      // Find Annual Income dropdown
      final incomeDropdown = dropdowns.firstWhere((d) {
        return d.items?.any((item) => item.value == 'Under ₹1 Lakh') == true;
      });
      final incomeItemValues =
          incomeDropdown.items?.map((item) => item.value).toList() ?? [];
      expect(incomeItemValues.contains('All'), isFalse,
          reason: 'Annual Income dropdown must not contain "All"');
      expect(incomeItemValues.contains('No Income'), isTrue,
          reason: 'Annual Income dropdown must contain "No Income"');
    });

    testWidgets('Student occupation automatically defaults Annual Income to "No Income"',
        (WidgetTester tester) async {
      final provider = AppProvider();
      // Set student profile
      provider.profile.employmentStatus = 'Student';

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: FilterPanel(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The Annual Income field should display "No Income"
      expect(find.text('No Income'), findsWidgets);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/app_theme.dart';
import 'package:frontend/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Themed Date Picker Tests', () {
    testWidgets('AppTheme.datePickerTheme defines correct colors and shapes', (tester) async {
      final theme = AppTheme.datePickerTheme;

      expect(theme.headerBackgroundColor, equals(AppConstants.primaryColor));
      expect(theme.headerForegroundColor, equals(Colors.white));
      expect(theme.backgroundColor, equals(AppConstants.surfaceColor));
      expect(theme.surfaceTintColor, equals(Colors.transparent));
      expect(theme.elevation, equals(6.0));
      expect(theme.shape, isA<RoundedRectangleBorder>());
      expect(theme.dividerColor, equals(AppConstants.cardBorderColor));

      // Day foreground & background state tests
      final selectedDayColor = theme.dayForegroundColor?.resolve({WidgetState.selected});
      expect(selectedDayColor, equals(Colors.white));

      final unselectedDayColor = theme.dayForegroundColor?.resolve({});
      expect(unselectedDayColor, equals(AppConstants.primaryText));

      final selectedDayBg = theme.dayBackgroundColor?.resolve({WidgetState.selected});
      expect(selectedDayBg, equals(AppConstants.primaryColor));

      final unselectedDayBg = theme.dayBackgroundColor?.resolve({});
      expect(unselectedDayBg, equals(Colors.transparent));

      // Today state tests
      final todaySelectedColor = theme.todayForegroundColor?.resolve({WidgetState.selected});
      expect(todaySelectedColor, equals(Colors.white));

      final todayUnselectedColor = theme.todayForegroundColor?.resolve({});
      expect(todayUnselectedColor, equals(AppConstants.primaryColor));

      // Year selector state tests
      final yearSelectedColor = theme.yearForegroundColor?.resolve({WidgetState.selected});
      expect(yearSelectedColor, equals(Colors.white));

      final yearUnselectedColor = theme.yearForegroundColor?.resolve({});
      expect(yearUnselectedColor, equals(AppConstants.primaryText));

      final yearSelectedBg = theme.yearBackgroundColor?.resolve({WidgetState.selected});
      expect(yearSelectedBg, equals(AppConstants.primaryColor));
    });

    testWidgets('showThemedDatePicker renders with themed dialog and actions', (tester) async {
      DateTime? pickedDate;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            primaryColor: AppConstants.primaryColor,
            scaffoldBackgroundColor: AppConstants.backgroundColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppConstants.primaryColor,
              primary: AppConstants.primaryColor,
              secondary: AppConstants.secondaryColor,
              error: AppConstants.errorColor,
            ),
            useMaterial3: true,
            datePickerTheme: AppTheme.datePickerTheme,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    pickedDate = await showThemedDatePicker(
                      context: context,
                      initialDate: DateTime(2024, 6, 15),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2030),
                      helpText: 'SELECT DATE OF BIRTH',
                    );
                  },
                  child: const Text('Open Date Picker'),
                );
              },
            ),
          ),
        ),
      );

      // Tap to open the picker
      await tester.tap(find.text('Open Date Picker'));
      await tester.pumpAndSettle();

      // Verify the date picker dialog is shown
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(find.text('SELECT DATE OF BIRTH'), findsOneWidget);

      // Verify action buttons (Cancel and OK)
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      // Tap OK to select the initial date
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Ensure picker dismissed and returned the date
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(pickedDate, equals(DateTime(2024, 6, 15)));
    });

    testWidgets('Standard showDatePicker inherits global datePickerTheme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            primaryColor: AppConstants.primaryColor,
            scaffoldBackgroundColor: AppConstants.backgroundColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppConstants.primaryColor,
              primary: AppConstants.primaryColor,
              secondary: AppConstants.secondaryColor,
              error: AppConstants.errorColor,
            ),
            useMaterial3: true,
            datePickerTheme: AppTheme.datePickerTheme,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDatePicker(
                      context: context,
                      initialDate: DateTime(2024, 1, 1),
                      firstDate: DateTime(1990),
                      lastDate: DateTime(2030),
                    );
                  },
                  child: const Text('Open Standard Picker'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Standard Picker'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
    });
  });
}

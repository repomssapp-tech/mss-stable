import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/profile/profile_eligibility_details_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> show(WidgetTester tester, UserProfile profile) async {
    final provider = AppProvider();
    await provider.updateProfile(profile);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ta')],
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileEligibilityDetailsCard(provider: provider),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows educationLevel (the synced field) over a stale '
      'qualification (issue 148)', (tester) async {
    await show(
      tester,
      UserProfile(qualification: 'Diploma', educationLevel: 'Graduate'),
    );
    expect(find.text('Graduate'), findsOneWidget);
    expect(find.textContaining('Diploma'), findsNothing);
  });

  testWidgets('falls back to qualification when educationLevel is empty', (
    tester,
  ) async {
    await show(tester, UserProfile(qualification: 'Diploma'));
    expect(find.textContaining('Diploma'), findsOneWidget);
  });
}

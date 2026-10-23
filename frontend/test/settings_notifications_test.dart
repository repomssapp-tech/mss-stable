import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget(AppProvider provider) {
    return ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('ta')],
        home: SettingsScreen(),
      ),
    );
  }

  group(
    'Settings - push notifications row (2.0: removed, no fake control)',
    () {
      testWidgets(
        'Settings no longer shows a notifications switch (it controlled '
        'nothing -- no push delivery exists)',
        (tester) async {
          final provider = AppProvider();
          provider.setLoggedInForTesting(true);

          await tester.pumpWidget(buildTestWidget(provider));
          await tester.pumpAndSettle();

          // The only switch left is the (real) haptics toggle.
          expect(find.byType(Switch), findsOneWidget);
          expect(find.text('Haptic feedback'), findsOneWidget);
          expect(find.textContaining('Notification'), findsNothing);
        },
      );

      test('profile.notificationsEnabled is still a real, persisted field '
          '(untouched -- just no longer surfaced in Settings)', () async {
        final provider = AppProvider();
        expect(provider.profile.notificationsEnabled, isTrue);

        await provider.updateProfile(
          provider.profile.copyWith(notificationsEnabled: false),
        );

        expect(provider.profile.notificationsEnabled, isFalse);
      });
    },
  );
}

import 'package:frontend/services/app_info_service.dart';
import 'package:frontend/utils/app_version.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/widgets/legal/copyright_notice.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp(AppProvider provider) {
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
        home: Scaffold(body: ProfileScreen()),
      ),
    );
  }

  testWidgets(
    'About tile has no subtitle and opens dialog without licenses button',
    (WidgetTester tester) async {
      AppInfoService.overrideForTest(const AppVersion(1, 0, 0, 7));
      addTearDown(AppInfoService.resetForTest);
      final provider = AppProvider();
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump();

      // Verify "About MSS app" subtitle is NOT rendered anywhere
      expect(find.text('About MSS app'), findsNothing);

      // Scroll until About tile is visible and tap it
      final aboutTile = find.text('About');
      expect(aboutTile, findsOneWidget);
      await tester.ensureVisible(aboutTile);
      await tester.tap(aboutTile);
      await tester.pumpAndSettle();

      // Verify Dialog content
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('MSS'), findsOneWidget);
      expect(find.text('v1.0.0 (7)'), findsOneWidget);
      // Once in the partner list and once in the copyright line.
      expect(
        find.textContaining('Rajalakshmi Institute of Technology'),
        findsNWidgets(2),
      );
      expect(find.textContaining('Swadeshi Shodh Sansthan'), findsNWidgets(2));
      expect(find.text(mssCopyrightLine), findsOneWidget);
      expect(find.text('Copyright & Intellectual Property'), findsOneWidget);
      expect(find.textContaining('mssschemessearch@gmail.com'), findsOneWidget);

      // Verify "View licenses" is completely removed
      expect(find.text('View licenses'), findsNothing);
      expect(find.text('VIEW LICENSES'), findsNothing);

      // Verify Close button dismisses dialog
      final closeButton = find.widgetWithText(ElevatedButton, 'Close');
      expect(closeButton, findsOneWidget);
      await tester.ensureVisible(closeButton);
      await tester.pumpAndSettle();
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    },
  );
}

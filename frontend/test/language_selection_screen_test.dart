import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/language_selection_screen.dart';
import 'package:frontend/services/catalog/language_pack_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  setUp(() {
    LanguagePackManager.instance.resetForTesting();
  });

  tearDown(() {
    LanguagePackManager.instance.resetForTesting();
  });

  Widget buildTestWidget() {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LanguageSelectionScreen(isOnboarding: false),
      ),
    );
  }

  group('LanguageSelectionScreen Hindi Visibility (Kill-Switch & Pack Validity)', () {
    testWidgets('State 1: Hidden when hi is inactive in release manifest (even if pack valid)', (tester) async {
      // Manifest explicitly sets hi as inactive
      LanguagePackManager.instance.isLanguageActiveOverride = (lang) => lang != 'hi';
      LanguagePackManager.instance.hasValidPackOverride = (lang) => true;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tamil is present
      expect(find.text('Tamil'), findsOneWidget);

      // Hindi is NOT shown
      expect(find.text('Hindi'), findsNothing);
      expect(find.text('हिन्दी'), findsNothing);
    });

    testWidgets('State 1b: Hidden when hi is active but pack is invalid or missing', (tester) async {
      LanguagePackManager.instance.isLanguageActiveOverride = (lang) => true;
      LanguagePackManager.instance.hasValidPackOverride = (lang) => lang != 'hi';

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Tamil'), findsOneWidget);
      expect(find.text('Hindi'), findsNothing);
      expect(find.text('हिन्दी'), findsNothing);
    });

    testWidgets('State 2: Visible when LanguagePackManager has valid hi pack AND release manifest lists hi as active', (tester) async {
      LanguagePackManager.instance.isLanguageActiveOverride = (lang) => true;
      LanguagePackManager.instance.hasValidPackOverride = (lang) => true;

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tamil and Hindi are both present
      expect(find.text('Tamil'), findsOneWidget);
      expect(find.text('Hindi'), findsOneWidget);
      expect(find.text('हिन्दी'), findsNWidgets(2));
    });
  });
}

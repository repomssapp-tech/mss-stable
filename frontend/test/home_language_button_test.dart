import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/home/home_header_section.dart';
import 'package:frontend/screens/regular_mode/home/home_language_button.dart';
import 'package:frontend/services/catalog/language_pack_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  Future<AppProvider> pumpButton(
    WidgetTester tester,
    Locale locale, {
    bool hiSupported = true,
  }) async {
    LanguagePackManager.instance.isLanguageActiveOverride = (_) => hiSupported;
    LanguagePackManager.instance.hasValidPackOverride = (_) => hiSupported;
    addTearDown(() {
      LanguagePackManager.instance.isLanguageActiveOverride = null;
      LanguagePackManager.instance.hasValidPackOverride = null;
    });
    final provider = AppProvider();
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(child: HomeLanguageButton(provider: provider)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return provider;
  }

  testWidgets('Hindi is hidden when the kill switch is off', (tester) async {
    await pumpButton(tester, const Locale('en'), hiSupported: false);

    await tester.tap(find.byType(HomeLanguageButton));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('தமிழ்'), findsOneWidget);
    expect(find.text('हिन्दी'), findsNothing);
  });

  testWidgets('menu lists English, Tamil and Hindi with the active one ticked',
      (tester) async {
    await pumpButton(tester, const Locale('en'));

    await tester.tap(find.byType(HomeLanguageButton));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('தமிழ்'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('button is labelled in the active UI language', (tester) async {
    await pumpButton(tester, const Locale('hi'));

    final hi = await AppLocalizations.delegate.load(const Locale('hi'));
    expect(find.byTooltip(hi.languageSetting), findsOneWidget);
  });

  for (final size in const [Size(320, 568), Size(360, 640)]) {
    testWidgets(
        'home header with the language button has no overflow in Hindi at '
        '${size.width.toInt()}x${size.height.toInt()} and 1.5x text scale',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = AppProvider();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('hi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: HomeHeaderSection(
                provider: provider,
                onNotificationTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeLanguageButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('choosing Hindi switches the app language to hi', (tester) async {
    final provider = await pumpButton(tester, const Locale('en'));
    expect(provider.selectedLanguage, isNot('hi'));

    await tester.tap(find.byType(HomeLanguageButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('हिन्दी'));
    await tester.pump();

    expect(provider.selectedLanguage, 'hi');
  });
}

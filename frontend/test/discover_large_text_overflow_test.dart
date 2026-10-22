// Issue #144 (UI-143-01): at Android font scale 1.6 the Discover category,
// ministry and utility cards overflowed and clipped their counts and
// descriptions in Hindi. Every card must reflow without a RenderFlex overflow.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/regular_mode/categories_screen.dart';
import 'package:frontend/services/catalog/language_pack_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    LanguagePackManager.instance.isLanguageActiveOverride = (_) => true;
    LanguagePackManager.instance.hasValidPackOverride = (_) => true;
    SharedPreferences.setMockInitialValues({});
  });

  tearDownAll(() {
    LanguagePackManager.instance.isLanguageActiveOverride = null;
    LanguagePackManager.instance.hasValidPackOverride = null;
  });

  for (final lang in ['hi', 'ta', 'en']) {
    for (final size in const [Size(1080, 2400), Size(720, 1280)]) {
      testWidgets('Discover has no overflow at text scale 1.6 ($lang, $size)', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final overflows = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          final msg = details.exceptionAsString();
          if (msg.contains('overflowed')) {
            overflows.add(msg.split('\n').first);
          } else {
            previous?.call(details);
          }
        };
        addTearDown(() => FlutterError.onError = previous);

        final provider = AppProvider()..setLoggedInForTesting(true);
        Widget tree() => ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: CategoriesScreen()),
          ),
        );
        provider.changeLanguage(lang);
        await tester.pumpWidget(tree());
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 400));
        }
        provider.changeLanguage(lang);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(tree());
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 400));
        }
        // Scroll through the whole screen so every section is laid out.
        final scrollable = find.byType(Scrollable).first;
        for (var i = 0; i < 12; i++) {
          await tester.drag(scrollable, const Offset(0, -400));
          await tester.pump(const Duration(milliseconds: 200));
        }

        expect(overflows, isEmpty, reason: overflows.toSet().join('\n'));
      });
    }
  }
}

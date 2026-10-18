import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/screens/profile/profile_value_formatters.dart';

Future<String> _format(WidgetTester tester, String locale, String value) async {
  late String out;
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          out = ProfileValueFormatters.getLocalizedProfileValue(value, context);
          return const SizedBox();
        },
      ),
    ),
  );
  return out;
}

void main() {
  testWidgets('English values render in the current language', (t) async {
    expect(await _format(t, 'hi', 'Male'), 'पुरुष');
    expect(await _format(t, 'ta', 'Male'), 'ஆண்');
    expect(await _format(t, 'hi', 'School'), 'स्कूल (10वीं/12वीं)');
    expect(await _format(t, 'hi', 'Minority'), 'अल्पसंख्यक');
  });

  testWidgets('a value stored in another language is re-rendered', (t) async {
    // Onboarding saves the tapped label, so these come from other locales.
    expect(await _format(t, 'ta', 'पुरुष'), 'ஆண்');
    expect(await _format(t, 'hi', 'ஆண்'), 'पुरुष');
    expect(await _format(t, 'en', 'पुरुष'), 'Male');
    expect(await _format(t, 'hi', 'மாணவர்'), 'विद्यार्थी');
  });

  testWidgets('unknown text is left unchanged', (t) async {
    expect(await _format(t, 'hi', 'Something custom'), 'Something custom');
  });
}

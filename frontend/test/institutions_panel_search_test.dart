import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/regular_mode/msme/msme_institutions_panel.dart';
import 'package:frontend/services/catalog/centralized_translator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tiic = 'Tamil Nadu Industrial Investment Corporation';
  const sidbi = 'Small Industries Development Bank of India';

  late String previousLanguage;

  setUpAll(() async {
    await CentralizedTranslator.instance.ensureLoaded();
  });

  setUp(() {
    previousLanguage = CentralizedTranslator.instance.activeLanguage;
    CentralizedTranslator.instance.activeLanguage = 'ta';
  });

  tearDown(() {
    CentralizedTranslator.instance.activeLanguage = previousLanguage;
  });

  Future<void> pumpPanel(WidgetTester tester) async {
    // The panel's tinted card wraps ExpansionTile; Flutter's debug-only
    // "ink may be invisible" assertion is a pre-existing visual note.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains(
        'ink splashes may be invisible',
      )) {
        return;
      }
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: InstitutionsInteractivePanel(iconColor: Colors.blue),
          ),
        ),
      ),
    );
  }

  testWidgets('Tamil query matches the displayed Tamil institution text', (
    tester,
  ) async {
    final tamilTiic = CentralizedTranslator.instance.localize(tiic);
    final tamilSidbi = CentralizedTranslator.instance.localize(sidbi);
    expect(tamilTiic, isNot(tiic), reason: 'dictionary must translate TIIC');
    expect(tamilSidbi, isNot(sidbi));

    await pumpPanel(tester);
    expect(find.text(tamilTiic), findsOneWidget);
    expect(find.text(tamilSidbi), findsOneWidget);

    final query = tamilTiic.substring(0, tamilTiic.length ~/ 2);
    await tester.enterText(find.byType(TextField), query);
    await tester.pump();

    expect(find.text(tamilTiic), findsOneWidget);
    expect(find.text(tamilSidbi), findsNothing);
  });

  testWidgets('English query still works in the Tamil locale', (tester) async {
    final tamilTiic = CentralizedTranslator.instance.localize(tiic);
    final tamilSidbi = CentralizedTranslator.instance.localize(sidbi);

    await pumpPanel(tester);
    await tester.enterText(find.byType(TextField), 'industrial investment');
    await tester.pump();

    expect(find.text(tamilTiic), findsOneWidget);
    expect(find.text(tamilSidbi), findsNothing);
  });
}

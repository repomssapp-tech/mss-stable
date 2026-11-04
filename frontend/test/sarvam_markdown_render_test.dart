// Saarthi replies arrive as markdown. They must render with real bold and
// bullets, not literal `**` and `- ` characters.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/design_v2/saarthi/saarthi_kit.dart';
import 'package:frontend/l10n/app_localizations.dart';

void main() {
  testWidgets('assistant markdown renders as styled spans, not raw characters', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SaarthiBubble(
            text: 'Here is **bold**, *italic* and a list:\n- one\n- two',
          ),
        ),
      ),
    );
    await tester.pump();

    // No literal markdown markers survive in any rendered text.
    for (final st in tester.widgetList<SelectableText>(
      find.byType(SelectableText),
    )) {
      final plain = st.textSpan?.toPlainText() ?? st.data ?? '';
      expect(plain.contains('**'), isFalse, reason: 'raw ** leaked: "$plain"');
      expect(
        plain.contains('- one'),
        isFalse,
        reason: 'raw bullet marker leaked: "$plain"',
      );
    }

    // The bold word is a real bold TextSpan.
    var foundBold = false;
    for (final st in tester.widgetList<SelectableText>(
      find.byType(SelectableText),
    )) {
      st.textSpan?.visitChildren((span) {
        if (span is TextSpan &&
            span.text == 'bold' &&
            span.style?.fontWeight == FontWeight.bold) {
          foundBold = true;
        }
        return true;
      });
    }
    expect(foundBold, isTrue, reason: 'expected a bold "bold" span');

    // Bullet content is still present.
    expect(find.textContaining('one'), findsWidgets);
    expect(find.textContaining('two'), findsWidgets);
  });
}

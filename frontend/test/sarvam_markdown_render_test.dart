// Regular-mode AI chat: model replies arrive as markdown. They must render
// with real bold / bullets, not literal `**` and `- ` characters.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/design_v2/saarthi/saarthi_type_screen.dart';
import 'package:frontend/services/chat/sarvam_chat_service.dart';

void main() {
  testWidgets('assistant markdown renders as styled spans, not raw characters',
      (tester) async {
    final client = _FakeSarvamChatClient();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SaarthiTypeScreen(
          client: client,
          profile: UserProfile(name: 'Anto'),
          language: 'en',
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('sarvam-chat-input')),
      'Explain MSME loans',
    );
    await tester.tap(find.byKey(const Key('sarvam-chat-send')));
    await tester.pump();

    client.resolve(
      'Here is **bold**, *italic* and a list:\n- one\n- two',
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // No literal markdown markers survive in any rendered text.
    for (final st in tester.widgetList<SelectableText>(
        find.byType(SelectableText))) {
      final plain = st.textSpan?.toPlainText() ?? st.data ?? '';
      expect(plain.contains('**'), isFalse, reason: 'raw ** leaked: "$plain"');
      expect(plain.contains('- one'), isFalse,
          reason: 'raw bullet marker leaked: "$plain"');
    }

    // The bold word is a real bold TextSpan.
    var foundBold = false;
    for (final st in tester.widgetList<SelectableText>(
        find.byType(SelectableText))) {
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

class _FakeSarvamChatClient implements SarvamChatClient {
  final _pending = <Completer<SarvamChatResponse>>[];

  @override
  Future<SarvamChatResponse> complete({
    required List<SarvamChatMessage> messages,
    required String language,
  }) {
    final completer = Completer<SarvamChatResponse>();
    _pending.add(completer);
    return completer.future;
  }

  void resolve(String text) =>
      _pending.removeAt(0).complete(SarvamChatResponse(reply: text));
}

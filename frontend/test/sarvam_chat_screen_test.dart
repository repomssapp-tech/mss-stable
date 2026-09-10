import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/screens/regular_mode/sarvam_chat_screen.dart';
import 'package:frontend/services/chat/sarvam_chat_service.dart';

void main() {
  testWidgets('shows a minimal conversation and sends trimmed text', (
    tester,
  ) async {
    final client = _FakeSarvamChatClient();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SarvamChatScreen(
          client: client,
          profile: UserProfile(name: 'Anto'),
          language: 'en',
        ),
      ),
    );

    expect(find.textContaining('How can I help?'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('sarvam-chat-input')),
      '  Find a business loan  ',
    );
    await tester.tap(find.byKey(const Key('sarvam-chat-send')));
    await tester.pump();
    expect(find.text('Find a business loan'), findsOneWidget);
    expect(find.byKey(const Key('sarvam-chat-thinking')), findsOneWidget);

    client.resolve('MUDRA may fit. Verify eligibility on the official portal.');
    await tester.pumpAndSettle();
    expect(
      find.text('MUDRA may fit. Verify eligibility on the official portal.'),
      findsOneWidget,
    );
    expect(client.lastMessages.last.content, 'Find a business loan');
  });

  testWidgets('keeps the message and offers retry after an API error', (
    tester,
  ) async {
    final client = _FakeSarvamChatClient();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SarvamChatScreen(
          client: client,
          profile: UserProfile(),
          language: 'en',
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('sarvam-chat-input')),
      'What can I apply for?',
    );
    await tester.tap(find.byKey(const Key('sarvam-chat-send')));
    await tester.pump();
    client.fail();
    await tester.pumpAndSettle();

    expect(find.text('What can I apply for?'), findsOneWidget);
    expect(find.byKey(const Key('sarvam-chat-retry')), findsOneWidget);
  });
}

class _FakeSarvamChatClient implements SarvamChatClient {
  final _pending = <Completer<SarvamChatResponse>>[];
  List<SarvamChatMessage> lastMessages = const [];

  @override
  Future<SarvamChatResponse> complete({
    required List<SarvamChatMessage> messages,
    required String language,
  }) {
    lastMessages = messages;
    final completer = Completer<SarvamChatResponse>();
    _pending.add(completer);
    return completer.future;
  }

  void resolve(String text) =>
      _pending.removeAt(0).complete(SarvamChatResponse(reply: text));

  void fail() => _pending
      .removeAt(0)
      .completeError(const SarvamChatException('Unable to reach Sarvam.'));
}

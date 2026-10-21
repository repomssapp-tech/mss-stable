import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/screens/regular_mode/sarvam_chat_screen.dart';
import 'package:frontend/services/chat/sarvam_chat_service.dart';

void main() {
  testWidgets(
    'reveals a reply gradually and keeps complete text in conversation history',
    (tester) async {
      final client = _FakeSarvamChatClient();
      await _openChat(tester, client);
      await _send(tester, 'Find a loan');
      const reply =
          'MUDRA may fit your business. Check the official eligibility rules.';
      client.resolve(reply);
      await tester.pump();
      expect(_replyText(tester), 'MUD');
      expect(find.byKey(const Key('sarvam-chat-thinking')), findsNothing);
      await tester.pump(const Duration(milliseconds: 90));
      expect(_replyText(tester), startsWith('MUDRA'));
      expect(_replyText(tester).length, lessThan(reply.length));
    await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(_replyText(tester), reply);
      await _send(tester, 'What documents?');
      expect(client.lastMessages[1].content, reply);
    },
  );

  testWidgets('long replies do not jump to the bottom while appearing', (
    tester,
  ) async {
    final client = _FakeSarvamChatClient();
    await _openChat(tester, client);
    await _send(tester, 'Explain the options');
    client.resolve(List.filled(100, 'Read each scheme carefully.').join(' '));
    await tester.pump();
    await tester.pump(const Duration(seconds: 45));
    await tester.pumpAndSettle();
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.controller!.position.maxScrollExtent, greaterThan(0));
    expect(list.controller!.offset, closeTo(0, 1));
  });

  testWidgets(
    'typing preserves whole Tamil graphemes and stops on navigation',
    (tester) async {
      final client = _FakeSarvamChatClient();
      await _openChat(tester, client);
      await _send(tester, 'Help');
      const reply = 'தமிழ் மொழியில் உதவி கிடைக்கும் 👨‍👩‍👧‍👦';
      client.resolve(reply);
      await tester.pump();
      expect(_replyText(tester), reply.characters.take(3).join());
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reduced motion shows the complete reply without a typing delay',
    (tester) async {
      final client = _FakeSarvamChatClient();
      await _openChat(tester, client, reduceMotion: true);
      await _send(tester, 'Help');
      const reply = 'Check the official scheme website for eligibility.';
      client.resolve(reply);
      await tester.pump();
      expect(_replyText(tester), reply);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('sarvam-chat-send')))
            .onPressed,
        isNotNull,
      );
    },
  );

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
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
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

  testWidgets('shows the AI disclaimer persistently, including on the welcome '
      'screen before any message is sent', (tester) async {
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

    const disclaimer =
        'AI can make mistakes. Check details on the official scheme website.';
    expect(find.text(disclaimer), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('sarvam-chat-input')),
      'Find a business loan',
    );
    await tester.tap(find.byKey(const Key('sarvam-chat-send')));
    await tester.pump();

    // Still shown once the thread has messages, not just on the empty
    // welcome screen.
    expect(find.text(disclaimer), findsOneWidget);
  });
}

Future<void> _openChat(
  WidgetTester tester,
  _FakeSarvamChatClient client, {
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: SarvamChatScreen(
        client: client,
        profile: UserProfile(),
        language: 'en',
      ),
    ),
  );
}

Future<void> _send(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('sarvam-chat-input')), text);
  await tester.tap(find.byKey(const Key('sarvam-chat-send')));
  await tester.pump(const Duration(milliseconds: 300));
}

String _replyText(WidgetTester tester) => tester
    .widgetList<SelectableText>(
      find.descendant(
        of: find.byKey(const ValueKey('sarvam-message-1')),
        matching: find.byType(SelectableText),
      ),
    )
    .map((text) => text.data ?? text.textSpan!.toPlainText())
    .join('\n');

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

// Saarthi v2 (Voice mode, history, voice settings, scheme mentions): the
// screen follows the conversation controller through Home -> Listening ->
// Confirm -> Conversation room and back; conversations are kept on the
// phone; the voice switches reach the controller.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/design_v2/saarthi/saarthi_history_screen.dart';
import 'package:frontend/design_v2/saarthi/saarthi_voice_screen.dart';
import 'package:frontend/design_v2/saarthi/saarthi_voice_settings_screen.dart';
import 'package:frontend/design_v2/saarthi/scheme_mentions.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/services/chat/local_chat_history.dart';
import 'package:frontend/services/search/scheme_understanding_engine.dart';
import 'package:frontend/services/voice/assistant_session_controller.dart';
import 'package:frontend/services/voice/http_voice_agent_controller.dart';
import 'package:frontend/services/voice/realtime_speech_transport.dart';
import 'package:frontend/services/voice/saarthi_conversation_controller.dart';
import 'package:frontend/services/voice/saarthi_voice_settings.dart';
import 'package:frontend/services/voice/voice_microphone.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Transport implements RealtimeSpeechTransport {
  final stream = StreamController<LiveSpeechEvent>.broadcast();
  @override
  Stream<LiveSpeechEvent> get events => stream.stream;
  @override
  Future<void> connect({
    required String language,
    required int silenceMs,
  }) async {}
  @override
  void audio(Uint8List bytes) {}
  @override
  void finish() {}
  @override
  Future<void> close() async {}
  @override
  Future<void> dispose() => stream.close();
}

class _Microphone implements VoiceMicrophone {
  @override
  Future<Stream<Uint8List>> start() async => const Stream.empty();
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

/// Drives the phases the screen draws, without audio or network.
class _Conversation extends SaarthiConversationController {
  _Conversation()
    : super(
        agent: HttpVoiceAgentController(
          session: AssistantSessionController(
            engine: const LocalSchemeUnderstandingEngine(),
            schemes: const [],
            profile: UserProfile(),
          ),
        ),
        transport: _Transport(),
        microphone: _Microphone(),
        language: 'en',
      );

  String? sent;
  int ends = 0;

  void _set(ConversationPhase p) {
    phase = p;
    notifyListeners();
  }

  @override
  Future<void> start() async {
    active = true;
    await resume();
  }

  @override
  Future<void> resume() async {
    editing = false;
    draft = '';
    _set(ConversationPhase.listening);
  }

  @override
  Future<void> finishTurn() async {
    draft = 'Find schemes for a food business';
    editing = true;
    _set(ConversationPhase.paused);
  }

  @override
  Future<void> send(String text) async {
    sent = text;
    editing = false;
    _set(ConversationPhase.thinking);
  }

  @override
  Future<void> pause() async {
    _set(ConversationPhase.paused);
  }

  @override
  Future<void> end() async {
    ends++;
    active = false;
    _set(ConversationPhase.idle);
  }
}

Future<LocalChatHistory> _tempHistory() async {
  final dir = await Directory.systemTemp.createTemp('mss_history_');
  addTearDown(() => dir.delete(recursive: true));
  return LocalChatHistory(directory: () async => dir);
}

Widget _app(Widget home, {Locale locale = const Locale('en')}) =>
    ChangeNotifierProvider<AppProvider>(
      create: (_) => AppProvider(),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SaarthiVoiceSettings.instance.resetForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.inschemes.app/voice_accessibility'),
          (_) async => false,
        );
  });

  group('Voice screen', () {
    testWidgets('home -> listening -> confirm -> send -> room -> end', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(720, 1560);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final c = _Conversation();
      addTearDown(() async {
        await c.agent.dispose();
      });
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.pumpWidget(
        _app(
          SaarthiVoiceScreen(
            conversation: c,
            history: LocalChatHistory.inMemory(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('sv2-home')), findsOneWidget);
      expect(
        find.byKey(const Key('saarthi-notifications-btn')),
        findsOneWidget,
      );

      // C1 -> C2
      await tester.tap(find.byKey(const Key('saarthi-start-speaking')));
      await tester.pump();
      expect(find.byKey(const Key('sv2-listening')), findsOneWidget);
      expect(find.text(l10n.sv2Listening('English')), findsOneWidget);

      // C2 -> C3 (review before sending is on by default)
      expect(c.reviewBeforeSend, isTrue);
      await tester.tap(find.byKey(const Key('sv2-finish-turn')));
      await tester.pump();
      expect(find.byKey(const Key('sv2-confirm')), findsOneWidget);
      expect(find.text(l10n.sv2ConfirmTitle), findsOneWidget);

      // C3 -> C4
      await tester.tap(find.bySemanticsLabel(l10n.sv2Send));
      await tester.pump();
      expect(c.sent, 'Find schemes for a food business');
      expect(find.byKey(const Key('sv2-room')), findsOneWidget);
      expect(find.byKey(const Key('live-voice-status')), findsOneWidget);
      expect(find.text(l10n.sv2Thinking), findsOneWidget);

      // End -> back home
      await tester.tap(find.bySemanticsLabel(l10n.sv2EndConversation));
      await tester.pump();
      expect(c.ends, greaterThan(0));
      expect(find.byKey(const Key('sv2-home')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('discarding the first request goes back home', (tester) async {
      tester.view.physicalSize = const Size(720, 1560);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final c = _Conversation();
      addTearDown(() async => c.agent.dispose());
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(
        _app(
          SaarthiVoiceScreen(
            conversation: c,
            history: LocalChatHistory.inMemory(),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('saarthi-start-speaking')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('sv2-finish-turn')));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(l10n.sv2Discard));
      await tester.pump();
      expect(c.sent, isNull);
      expect(find.byKey(const Key('sv2-home')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the voice switches reach the conversation', (tester) async {
      final c = _Conversation();
      addTearDown(() async => c.agent.dispose());
      await tester.pumpWidget(
        _app(
          SaarthiVoiceScreen(
            conversation: c,
            history: LocalChatHistory.inMemory(),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('saarthi-start-speaking')));
      await tester.pump();
      // Defaults: confirm on, hands-free off, read aloud on.
      expect(c.reviewBeforeSend, isTrue);
      expect(c.handsFree, isFalse);
      expect(c.agent.speakReplies, isTrue);

      await SaarthiVoiceSettings.instance.update(
        confirmBeforeSend: false,
        handsFree: true,
        autoplay: false,
      );
      await tester.pump();
      expect(c.reviewBeforeSend, isFalse);
      expect(c.handsFree, isTrue);
      expect(c.agent.speakReplies, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    for (final code in ['ta', 'hi']) {
      testWidgets('home renders in $code without overflow', (tester) async {
        tester.view.physicalSize = const Size(720, 1560);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        final c = _Conversation();
        addTearDown(() async => c.agent.dispose());
        await tester.pumpWidget(
          _app(
            SaarthiVoiceScreen(
              conversation: c,
              history: LocalChatHistory.inMemory(),
            ),
            locale: Locale(code),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('LocalChatHistory', () {
    SavedChat chat(String id, DateTime at, String text) => SavedChat(
      id: id,
      mode: 'type',
      createdAt: at,
      updatedAt: at,
      messages: [SavedChatMessage(role: 'user', text: text, at: at)],
    );

    test('saves, survives a reload, lists newest first, deletes', () async {
      final h = await _tempHistory();
      await h.save(chat('a', DateTime(2026, 10, 20), 'Older question'));
      await h.save(chat('b', DateTime(2026, 10, 24), 'Newer question'));
      h.resetCache();
      final listed = await h.list();
      expect(listed.map((c) => c.id), ['b', 'a']);
      expect(listed.first.title, 'Newer question');
      await h.delete('b');
      h.resetCache();
      expect((await h.list()).map((c) => c.id), ['a']);
      await h.clear();
      expect(await h.list(), isEmpty);
    });

    test('an empty conversation is not kept; the newest 100 are', () async {
      final h = await _tempHistory();
      await h.save(
        SavedChat(
          id: 'empty',
          mode: 'voice',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          messages: const [],
        ),
      );
      expect(await h.list(), isEmpty);
      for (var i = 0; i < LocalChatHistory.maxChats + 5; i++) {
        await h.save(chat('c$i', DateTime(2026, 1, 1, 0, i), 'q$i'));
      }
      final listed = await h.list();
      expect(listed, hasLength(LocalChatHistory.maxChats));
      expect(listed.first.id, 'c${LocalChatHistory.maxChats + 4}');
    });
  });

  testWidgets('history groups, searches and opens a voice transcript', (
    tester,
  ) async {
    final h = LocalChatHistory.inMemory();
    final now = DateTime(2026, 10, 24, 12);
    await h.save(
      SavedChat(
        id: 'v1',
        mode: 'voice',
        createdAt: now,
        updatedAt: now,
        messages: [
          SavedChatMessage(role: 'user', text: 'Loans for women', at: now),
          SavedChatMessage(
            role: 'assistant',
            text: 'Stand-Up India may fit.',
            at: now,
          ),
        ],
      ),
    );
    final old = DateTime(2026, 10, 10);
    await h.save(
      SavedChat(
        id: 't1',
        mode: 'type',
        createdAt: old,
        updatedAt: old,
        messages: [
          SavedChatMessage(
            role: 'user',
            text: 'Am I eligible for PMEGP?',
            at: old,
          ),
        ],
      ),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(
      _app(SaarthiHistoryScreen(history: h, now: () => now)),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.notifToday.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.notifEarlier.toUpperCase()), findsOneWidget);
    expect(find.text('Loans for women'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('sv2-history-search')),
      'pmegp',
    );
    await tester.pump();
    expect(find.text('Loans for women'), findsNothing);
    expect(find.text('Am I eligible for PMEGP?'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('sv2-history-search')), '');
    await tester.pump();
    await tester.tap(find.text('Loans for women'));
    await tester.pumpAndSettle();
    expect(find.byType(SaarthiTranscriptScreen), findsOneWidget);
    expect(
      find.text('Stand-Up India may fit.', findRichText: true),
      findsWidgets,
    );
  });

  testWidgets('voice settings save the switches and the language', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(_app(const SaarthiVoiceSettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text(l10n.sv2HandsFree), findsOneWidget);
    await tester.tap(find.text(l10n.sv2HandsFree));
    await tester.pumpAndSettle();
    expect(SaarthiVoiceSettings.instance.handsFree, isTrue);

    await tester.tap(find.byKey(const Key('sv2-voice-lang-mr')));
    await tester.pumpAndSettle();
    expect(SaarthiVoiceSettings.instance.languageChange, 'mr');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('saarthi_voice_language_v1'), 'mr');
  });

  group('schemesMentionedIn', () {
    const pmegp = Scheme(
      id: 'CEN-1',
      name: "Prime Minister's Employment Generation Programme (PMEGP)",
      shortName: 'PMEGP',
    );
    const mudra = Scheme(
      id: 'CEN-2',
      name: 'Pradhan Mantri Mudra Yojana',
      shortName: 'PMMY',
    );
    const other = Scheme(id: 'CEN-3', name: 'Something Else Entirely');

    test('finds acronyms and full names in the order named', () {
      expect(
        schemesMentionedIn(
          'Try Pradhan Mantri Mudra Yojana first, then PMEGP.',
          const [pmegp, mudra, other],
        ).map((s) => s.id),
        ['CEN-2', 'CEN-1'],
      );
    });

    test('an acronym must be a whole word', () {
      expect(
        schemesMentionedIn('XPMEGPX is not a scheme', const [pmegp]),
        isEmpty,
      );
    });
  });
}

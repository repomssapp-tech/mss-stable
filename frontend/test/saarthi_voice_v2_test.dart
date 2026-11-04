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
import 'package:frontend/utils/app_colors.dart';
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
  String? heard;
  int ends = 0;

  void hearSound(Uint8List bytes) => reportInput(bytes);

  @override
  Future<void> hear(String reply) async {
    heard = reply;
  }

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
    await send('Find schemes for a food business');
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
      expect(find.byKey(const Key('saarthi-profile-btn')), findsOneWidget);

      // Home -> listening
      await tester.tap(find.byKey(const Key('saarthi-start-speaking')));
      await tester.pump();
      expect(find.byKey(const Key('sv2-listening')), findsOneWidget);
      expect(find.text(l10n.sv2Listening('English')), findsOneWidget);

      // Finishing the turn sends straight away, with no review step
      expect(c.reviewBeforeSend, isFalse);
      await tester.tap(find.byKey(const Key('sv2-finish-turn')));
      await tester.pump();
      expect(c.sent, 'Find schemes for a food business');
      expect(find.byKey(const Key('sv2-room')), findsOneWidget);
      expect(find.byKey(const Key('live-voice-status')), findsOneWidget);
      expect(find.text(l10n.sv2Thinking), findsOneWidget);

      // The Home tab ends the conversation
      await tester.tap(find.byKey(const Key('sv2-nav-home')));
      await tester.pump();
      expect(c.ends, greaterThan(0));
      expect(find.byKey(const Key('sv2-home')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the pill is grey until connected; its bars follow sound', (
      tester,
    ) async {
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
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('saarthi-start-speaking')));
      await tester.pump();

      Color pill() => tester
          .widget<Material>(find.byKey(const Key('sv2-wave-pill')))
          .color!;
      double bar() =>
          tester.getSize(find.byKey(const Key('sv2-wave-14'))).height;

      c._set(ConversationPhase.connecting);
      await tester.pump();
      expect(pill(), AppColors.disabledBg);
      await tester.tap(find.byKey(const Key('sv2-finish-turn')));
      await tester.pump();
      expect(c.sent, isNull, reason: 'cannot finish before connecting');

      c._set(ConversationPhase.listening);
      await tester.pump();
      expect(pill(), AppColors.primary);
      await tester.pump(const Duration(milliseconds: 100));
      expect(bar(), 6, reason: 'silence stays flat');

      c.hearSound(Uint8List.fromList([0, 32, 0, 32]));
      await tester.pump(const Duration(milliseconds: 100));
      expect(bar(), greaterThan(20));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Back stays inside Saarthi and never exits from a chat', (
      tester,
    ) async {
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
        ),
      );
      await tester.pump();
      expect(SaarthiVoiceScreen.handlesBack, isFalse);

      await tester.tap(find.byKey(const Key('saarthi-start-typing')));
      await tester.pump();
      await tester.pump();
      expect(SaarthiVoiceScreen.handlesBack, isTrue);

      await tester.binding.handlePopRoute();
      expect(
        SaarthiVoiceScreen.handlesBack,
        isTrue,
        reason: 'still true while the shell handler runs',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sv2-home')), findsOneWidget);
      expect(SaarthiVoiceScreen.handlesBack, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the keyboard starts a typed chat without the mic', (
      tester,
    ) async {
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
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('saarthi-start-typing')));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('sv2-room')), findsOneWidget);
      expect(c.phase, ConversationPhase.idle);

      await tester.enterText(
        find.byKey(const Key('sarvam-chat-input')),
        'Schemes for farmers',
      );
      await tester.tap(find.byKey(const Key('sarvam-chat-send')));
      await tester.pump();
      expect(c.sent, 'Schemes for farmers');
      expect(c.agent.speakReplies, isTrue, reason: 'restored after the turn');

      // The small mic goes back to speaking in the same chat.
      await tester.tap(find.byKey(const Key('sv2-composer-mic')));
      await tester.pump();
      expect(find.byKey(const Key('sv2-listening')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a saved spoken chat reopens, continues and can be re-heard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(720, 1560);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final c = _Conversation();
      addTearDown(() async => c.agent.dispose());
      final h = LocalChatHistory.inMemory();
      final at = DateTime(2026, 10, 24, 12);
      await h.save(
        SavedChat(
          id: 'v1',
          mode: 'voice',
          createdAt: at,
          updatedAt: at,
          messages: [
            SavedChatMessage(role: 'user', text: 'Loans for women', at: at),
            SavedChatMessage(role: 'assistant', text: 'Try Stand-Up.', at: at),
          ],
        ),
      );
      await tester.pumpWidget(
        _app(SaarthiVoiceScreen(conversation: c, history: h)),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('sv2-nav-sessions')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Loans for women'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sv2-room')), findsOneWidget);
      expect(c.phase, ConversationPhase.idle, reason: 'mic stays off');
      expect(c.agent.conversationHistory.map((m) => m['content']), [
        'Loans for women',
        'Try Stand-Up.',
      ]);

      await tester.tap(find.byKey(const Key('sv2-hear-1')));
      await tester.pump();
      expect(c.heard, 'Try Stand-Up.');

      await tester.tap(find.byKey(const Key('sv2-room-mic')));
      await tester.pump();
      expect(find.byKey(const Key('sv2-listening')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the voice switches reach the conversation', (tester) async {
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
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('saarthi-start-speaking')));
      await tester.pump();
      // The mic always reopens after a reply; read aloud is on by default.
      expect(c.handsFree, isTrue);
      expect(c.agent.speakReplies, isTrue);

      await SaarthiVoiceSettings.instance.update(autoplay: false);
      await tester.pump();
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

    test('each account sees only its own chats', () async {
      final dir = await Directory.systemTemp.createTemp('mss_history_');
      addTearDown(() => dir.delete(recursive: true));
      String? user = 'asha';
      final h = LocalChatHistory(directory: () async => dir, owner: () => user);
      await h.save(chat('a', DateTime(2026, 10, 20), 'Asha question'));

      user = 'ravi';
      expect(await h.list(), isEmpty);
      await h.save(chat('r', DateTime(2026, 10, 21), 'Ravi question'));
      await h.clear();

      user = 'asha';
      expect((await h.list()).map((c) => c.id), ['a']);
    });

    test('the old shared file moves to the first account only', () async {
      final dir = await Directory.systemTemp.createTemp('mss_history_');
      addTearDown(() => dir.delete(recursive: true));
      final old = LocalChatHistory(
        directory: () async => dir,
        owner: () => null,
      );
      await old.save(chat('o', DateTime(2026, 10, 20), 'Old question'));
      await File(
        '${dir.path}/saarthi_history_guest_v1.json',
      ).rename('${dir.path}/${LocalChatHistory.fileName}');

      String? user = 'asha';
      final h = LocalChatHistory(directory: () async => dir, owner: () => user);
      expect((await h.list()).map((c) => c.id), ['o']);
      user = 'ravi';
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
    expect(find.text(l10n.sv2Autoplay), findsOneWidget);
    await tester.tap(find.text(l10n.sv2Autoplay));
    await tester.pumpAndSettle();
    expect(SaarthiVoiceSettings.instance.autoplay, isFalse);

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

    test('voice cards show only the schemes the reply names', () {
      const hit = CloudSchemeResult(
        id: 'CEN-3',
        code: 'CEN-3',
        name: 'Something',
      );
      // A search hit the reply never mentions gets no card.
      expect(
        schemesForReply(
          'Try PMEGP first.',
          const [pmegp, other],
          results: const [hit],
        ).map((s) => s.id),
        ['CEN-1'],
      );
      expect(
        schemesForReply(
          'I need your state.',
          const [pmegp, other],
          results: const [hit],
        ),
        isEmpty,
      );
      // A hit counts when the reply says its title.
      const said = CloudSchemeResult(
        id: 'CEN-3',
        code: 'CEN-3',
        name: 'திட்டம் மூன்று',
      );
      expect(
        schemesForReply(
          'திட்டம் மூன்று உதவும்',
          const [pmegp, other],
          results: const [said],
        ).map((s) => s.id),
        ['CEN-3'],
      );
    });

    test('an acronym matches when split up or spelled in Hindi or Tamil', () {
      for (final reply in [
        'Try P.M.E.G.P today.',
        'Try P M E G P today.',
        'पीएमईजीपी योजना देखें',
        'पी.एम.ई.जी.पी योजना देखें',
        'பிஎம்இஜிபி திட்டம் பாருங்கள்',
        'பி.எம்.இ.ஜி.பி திட்டம் பாருங்கள்',
        'பிஎம்இஜிபியில் சேரலாம்',
      ]) {
        expect(
          schemesMentionedIn(reply, const [pmegp, other]).map((s) => s.id),
          ['CEN-1'],
          reason: reply,
        );
      }
    });

    test('names ignore punctuation, spelling and Hindi or Tamil endings', () {
      const named = Scheme(
        id: 'CEN-4',
        name: "Prime Minister's Awas Programme",
        nativeNames: {
          'name': {'ta': 'பிரதம மந்திரி வீட்டு திட்டம்'},
          'shortName': {'hi': 'प्रधानमंत्री आवास योजना'},
        },
      );
      for (final reply in [
        'The Prime Ministers Awas Program helps.',
        'பிரதம மந்திரி வீட்டு திட்டத்தின் கீழ் உதவி கிடைக்கும்',
        'प्रधानमंत्री आवास योजना से मदद मिलेगी',
      ]) {
        expect(
          schemesMentionedIn(reply, const [named, other]).map((s) => s.id),
          ['CEN-4'],
          reason: reply,
        );
      }
    });

    test('one unique word of a name counts only for a search hit', () {
      const hit = CloudSchemeResult(id: 'CEN-2', code: 'CEN-2', name: '');
      const reply = 'Mudra gives small loans.';
      expect(
        schemesForReply(
          reply,
          const [mudra, other],
          results: const [hit],
        ).map((s) => s.id),
        ['CEN-2'],
      );
      expect(
        schemesForReply(reply, const [mudra, other], results: const []),
        isEmpty,
      );
      // A word another scheme's name also has says nothing.
      const mudraTwo = Scheme(id: 'CEN-5', name: 'Mudra Support Plan');
      expect(
        schemesForReply(reply, const [mudra, mudraTwo], results: const [hit]),
        isEmpty,
      );
    });

    test('schemes sharing a name give one card, the search hit first', () {
      const twin = Scheme(
        id: 'TN-1',
        name: 'PMEGP Tamil Nadu Window',
        shortName: 'PMEGP',
      );
      const hit = CloudSchemeResult(id: 'TN-1', code: 'TN-1', name: '');
      expect(
        schemesForReply(
          'Try PMEGP.',
          const [pmegp, twin],
          results: const [hit],
        ).map((s) => s.id),
        ['TN-1'],
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

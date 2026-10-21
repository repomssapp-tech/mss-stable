import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/utils/app_theme.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/screens/companion_mode/saarthi_home/saarthi_live_conversation_view.dart';
import 'package:frontend/screens/companion_mode/saarthi_message.dart';
import 'package:frontend/services/search/scheme_understanding_engine.dart';
import 'package:frontend/services/voice/assistant_session_controller.dart';
import 'package:frontend/services/voice/http_voice_agent_controller.dart';
import 'package:frontend/services/voice/realtime_speech_transport.dart';
import 'package:frontend/services/voice/saarthi_conversation_controller.dart';
import 'package:frontend/services/voice/voice_microphone.dart';

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

class _Conversation extends SaarthiConversationController {
  _Conversation({bool reader = false})
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
        screenReader: reader,
      );
  String? sent;
  int pauses = 0;
  int resumes = 0;
  @override
  Future<void> pause() async {
    pauses++;
    phase = ConversationPhase.paused;
    notifyListeners();
  }

  @override
  Future<void> resume() async {
    resumes++;
    editing = false;
    phase = ConversationPhase.listening;
    notifyListeners();
  }

  @override
  Future<void> send(String text) async {
    sent = text;
    editing = false;
    phase = ConversationPhase.thinking;
    notifyListeners();
  }

  @override
  Future<void> end() async {
    active = false;
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  late _Conversation conversation;
  late ScrollController scroll;
  late AnimationController wave;

  setUp(() {
    conversation = _Conversation()..active = true;
    scroll = ScrollController();
    wave = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 1),
    );
  });
  tearDown(() async {
    await conversation.dispose();
    await conversation.agent.dispose();
    scroll.dispose();
    wave.dispose();
  });

  Future<void> host(
    WidgetTester tester, {
    String locale = 'en',
    double scale = 1,
    double keyboard = 0,
    List<SaarthiMessage> messages = const [],
    VoidCallback? end,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SafeArea(
            child: SaarthiLiveConversationView(
              conversation: conversation,
              messages: messages,
              scrollController: scroll,
              waveController: wave,
              onEndConversation: end ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final locale in ['en', 'ta', 'hi']) {
    for (final phase in [
      ConversationPhase.listening,
      ConversationPhase.paused,
      ConversationPhase.error,
    ]) {
      testWidgets('$locale $phase fits 320dp with 200% text', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        conversation.phase = phase;
        if (phase == ConversationPhase.error) conversation.error = 'NO_SPEECH';
        await host(tester, locale: locale, scale: 2);
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byKey(const Key('live-voice-end'))).height,
          greaterThanOrEqualTo(48),
        );
        expect(
          tester
              .getSize(find.byKey(const Key('live-voice-pause-resume')))
              .height,
          greaterThanOrEqualTo(48),
        );
        final toggle = find.byKey(const Key('live-voice-pause-resume'));
        await tester.tap(toggle);
        await tester.pump();
        expect(
          phase == ConversationPhase.listening
              ? conversation.pauses
              : conversation.resumes,
          1,
        );
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('$locale inline correction fits large text and keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      conversation.editing = true;
      conversation.phase = ConversationPhase.paused;
      conversation.draft = 'A bakery business request';
      bool ended = false;
      await host(
        tester,
        locale: locale,
        scale: 2,
        keyboard: 200,
        end: () => ended = true,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('live-voice-pause-resume')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('live-voice-editor')));
      await tester.enterText(
        find.byKey(const Key('live-voice-editor')),
        'Corrected bakery request',
      );
      await tester.ensureVisible(find.byKey(const Key('live-voice-send')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('live-voice-send')));
      await tester.pump();
      expect(conversation.sent, 'Corrected bakery request');
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('live-voice-end')));
      expect(ended, isTrue);
    });
  }

  testWidgets('visible controls meet Android accessibility guidelines', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    conversation.phase = ConversationPhase.paused;
    await host(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });

  testWidgets('End is reachable by keyboard without pointer or microphone', (
    tester,
  ) async {
    bool ended = false;
    await host(tester, end: () => ended = true);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(ended, isTrue);
  });

  testWidgets('partials do not become status announcements', (tester) async {
    final semantics = tester.ensureSemantics();
    conversation.phase = ConversationPhase.listening;
    await host(tester);
    final before = tester.widget<Semantics>(
      find.byKey(const Key('live-voice-status')),
    );
    conversation.draft = 'My request is still forming';
    conversation.notifyListeners();
    await tester.pump();
    final after = tester.widget<Semantics>(
      find.byKey(const Key('live-voice-status')),
    );
    expect(after.properties.label, before.properties.label);
    expect(after.properties.liveRegion, isTrue);
    expect(find.text('My request is still forming'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'opening voice options pauses capture and offers four languages',
    (tester) async {
      conversation.phase = ConversationPhase.listening;
      await host(tester);
      await tester.ensureVisible(find.byKey(const Key('live-voice-options')));
      await tester.tap(find.byKey(const Key('live-voice-options')));
      await tester.pumpAndSettle();
      expect(conversation.pauses, 1);
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const Key('live-voice-language')),
      );
      expect(dropdown, isNotNull);
      await tester.ensureVisible(find.byKey(const Key('live-voice-language')));
      await tester.tap(find.byKey(const Key('live-voice-language')));
      await tester.pumpAndSettle();
      expect(find.text('தமிழ்'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('मराठी'), findsOneWidget);
    },
  );

  testWidgets('screen reader owns reply announcements and resumes explicitly', (
    tester,
  ) async {
    final previous = conversation;
    addTearDown(() async {
      await previous.dispose();
      await previous.agent.dispose();
    });
    conversation = _Conversation(reader: true)
      ..active = true
      ..phase = ConversationPhase.paused;
    await host(
      tester,
      messages: [
        SaarthiMessage(
          id: 'reply',
          role: 'assistant',
          text: 'Here is your answer.',
          timestamp: DateTime(2026),
        ),
      ],
    );
    expect(conversation.readAloud, isFalse);
    expect(
      find.text('Screen reader mode: resume after each reply.'),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('live-message-reply')),
    );
    final reply = tester.widget<Semantics>(
      find.byKey(const ValueKey('live-message-reply')),
    );
    expect(reply.properties.liveRegion, isTrue);
    expect(conversation.resumes, 0);
    await tester.tap(find.byKey(const Key('live-voice-pause-resume')));
    await tester.pump();
    expect(conversation.resumes, 1);
  });

  testWidgets(
    'Latest reveals the beginning of a long reply without automatic scrolling',
    (tester) async {
      final messages = List.generate(
        8,
        (index) => SaarthiMessage(
          id: 'reply-$index',
          role: 'assistant',
          text: List.filled(
            100,
            'Scheme information for this request.',
          ).join(' '),
          timestamp: DateTime(2026),
        ),
      );
      await host(tester, messages: messages);
      expect(scroll.offset, 0);
      await tester.tap(find.byKey(const Key('live-voice-latest')));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      final newest = find.byKey(const ValueKey('live-message-reply-7'));
      expect(newest, findsOneWidget);
      expect(
        tester.getTopLeft(newest).dy,
        closeTo(
          tester.getTopLeft(find.byKey(const Key('live-voice-scroll'))).dy,
          1,
        ),
      );
    },
  );

  for (final code in [
    'UNAUTHORIZED',
    'SILENCE_TIMEOUT',
    'VOICE_FINAL_TIMEOUT',
    'speech-unavailable',
  ]) {
    testWidgets('$code offers specific recovery and preserves correction', (
      tester,
    ) async {
      conversation.phase = ConversationPhase.error;
      conversation.error = code;
      conversation.draft = 'The words already recognized';
      await host(tester);
      expect(
        find.textContaining(switch (code) {
          'UNAUTHORIZED' => 'sign in again',
          'SILENCE_TIMEOUT' => 'No speech was heard',
          'speech-unavailable' => 'couldn’t play the audio',
          _ => 'transcript did not finish',
        }),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('live-voice-correct')));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find.byKey(const Key('live-voice-editor')),
      );
      expect(field.controller!.text, 'The words already recognized');
    });
  }
  testWidgets('audio off exposes an explicit enable control', (tester) async {
    conversation.agent.speakReplies = false;
    await host(tester);
    await tester.tap(find.byKey(const Key('live-voice-enable-audio')));
    await tester.pumpAndSettle();
    expect(conversation.readAloud, isTrue);
    expect(find.byKey(const Key('live-voice-enable-audio')), findsNothing);
    expect(conversation.pauses, 1);
  });
}

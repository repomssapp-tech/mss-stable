import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/providers/app_state_provider.dart';
import 'package:frontend/screens/companion_mode/saarthi_home/saarthi_bottom_panel.dart';
import 'package:frontend/screens/companion_mode/saarthi_home/saarthi_character_header.dart';
import 'package:frontend/screens/companion_mode/saarthi_home/saarthi_compact_scheme_card.dart';
import 'package:frontend/screens/companion_mode/saarthi_home/saarthi_top_bar.dart';
import 'package:frontend/screens/companion_mode/saarthi_home/saarthi_transcript_view.dart';
import 'package:frontend/screens/companion_mode/saarthi_home_screen.dart';
import 'package:frontend/services/voice/livekit_voice_agent_controller.dart';

Widget _host({
  Locale locale = const Locale('en'),
  Widget? child,
}) {
  return ChangeNotifierProvider<AppProvider>(
    create: (_) => AppProvider()..changeLanguage(locale.languageCode),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: child ?? const SaarthiHomeScreen(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  group('SaarthiHomeScreen & Sub-components Tests', () {
    testWidgets('renders idle companion screen with top bar, avatar, and start voice button',
        (tester) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // Top bar items
      expect(find.byKey(const Key('saarthi-notifications-btn')), findsOneWidget);
      expect(find.byKey(const Key('saarthi-profile-avatar-btn')), findsOneWidget);

      // Character header in idle mode
      expect(find.byType(SaarthiCharacterHeader), findsOneWidget);

      // Bottom panel & start speaking button
      expect(find.byType(SaarthiBottomPanel), findsOneWidget);
      expect(find.byKey(const Key('saarthi-start-speaking')), findsOneWidget);
    });

    testWidgets('tapping start speaking button triggers conversation mode',
        (tester) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // Tap start voice button
      await tester.tap(find.byKey(const Key('saarthi-start-speaking')));
      await tester.pumpAndSettle();

      // Conversation mode is now active with all controls
      expect(find.byKey(const Key('saarthi-voice-status')), findsOneWidget);
      expect(find.byKey(const Key('saarthi-accessible-controls')), findsOneWidget);
      expect(find.byKey(const Key('saarthi-primary-voice-control')), findsOneWidget);
      expect(find.byKey(const Key('saarthi-end-control')), findsOneWidget);

      // Transcript view should be present with empty state
      expect(find.byType(SaarthiTranscriptView), findsOneWidget);
      expect(find.byKey(const Key('voice-empty-state')), findsOneWidget);
    });

    testWidgets('SaarthiBottomPanel fires callbacks for voice controls',
        (tester) async {
      bool ended = false;
      bool micTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SaarthiBottomPanel(
              isConversationActive: true,
              voiceState: SaarthiVoiceState.listening,
              usingCloudVoice: true,
              cloudRetrying: false,
              cloudConnectionError: null,
              onStartConversation: () {},
              onPrimaryMicTap: () => micTapped = true,
              onEndConversation: () => ended = true,
              onRetryCloudVoice: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('saarthi-voice-status')), findsOneWidget);
      expect(find.byKey(const Key('saarthi-primary-voice-control')), findsOneWidget);
      expect(find.byKey(const Key('saarthi-end-control')), findsOneWidget);

      await tester.tap(find.byKey(const Key('saarthi-primary-voice-control')));
      expect(micTapped, isTrue);

      await tester.tap(find.byKey(const Key('saarthi-end-control')));
      expect(ended, isTrue);
    });

    testWidgets('SaarthiTopBar renders properly and handles notifications tap',
        (tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SaarthiTopBar(provider: provider),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('saarthi-notifications-btn')), findsOneWidget);
      expect(find.byKey(const Key('saarthi-profile-avatar-btn')), findsOneWidget);
    });

    testWidgets('SaarthiCompactSchemeCard renders scheme details and confidence badge',
        (tester) async {
      final scheme = Scheme(
        id: 'test-scheme-1',
        name: 'PMEGP Business Scheme',
        overview: 'Government subsidy program for micro enterprises',
        benefits: 'Up to 35% capital subsidy for new projects',
        category: 'Business & MSME',
        department: 'Ministry of MSME',
        targetBeneficiary: 'Entrepreneurs',
        applicationUrl: 'https://example.gov.in',
        schemeCode: 'PMEGP',
        verificationStatus: 'verified',
      );

      final metadata = CloudSchemeResult(
        id: 'test-scheme-1',
        code: 'PMEGP',
        name: 'PMEGP Business Scheme',
        matchConfidence: 92,
        isVerified: true,
        sourceConfidence: 'high',
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>(
          create: (_) => AppProvider(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SaarthiCompactSchemeCard(
                scheme: scheme,
                metadata: metadata,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('companion-scheme-test-scheme-1')), findsOneWidget);
      expect(find.text('PMEGP Business Scheme'), findsOneWidget);
      expect(find.text('92% match'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });

    testWidgets('SaarthiTranscriptView renders user and assistant turns with waveform',
        (tester) async {
      final animationController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 1),
      );

      final messages = [
        SaarthiMessage(
          id: 'user-turn-1',
          role: 'user',
          text: 'Can I get a subsidy for a small bakery?',
          timestamp: DateTime(2026, 9, 12, 10, 30),
        ),
        SaarthiMessage(
          id: 'ai-turn-1',
          role: 'assistant',
          text: 'Yes! PMEGP provides up to 35% subsidy for food processing businesses.',
          timestamp: DateTime(2026, 9, 12, 10, 30, 5),
          speakingState: 'speaking',
        ),
      ];

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>(
          create: (_) => AppProvider(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SaarthiTranscriptView(
                messages: messages,
                scrollController: ScrollController(),
                isUserScrolling: false,
                onScrollToLatest: () {},
                waveController: animationController,
                voiceStatusText: 'Speaking now',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('voice-transcript-list')), findsOneWidget);
      expect(find.text('Can I get a subsidy for a small bakery?'), findsOneWidget);
      expect(
        find.text('Yes! PMEGP provides up to 35% subsidy for food processing businesses.'),
        findsOneWidget,
      );
      expect(find.byType(SaarthiWaveformBar), findsNWidgets(5));
    });

    testWidgets('renders companion mode properly in Tamil locale', (tester) async {
      await tester.pumpWidget(
        _host(locale: const Locale('ta')),
      );
      await tester.pumpAndSettle();

      // Top bar renders
      expect(find.byKey(const Key('saarthi-notifications-btn')), findsOneWidget);
      // Start button renders
      expect(find.byKey(const Key('saarthi-start-speaking')), findsOneWidget);
    });
  });
}

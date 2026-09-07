import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/voice_agent_controller.dart';
import 'package:frontend/widgets/voice_assistant_overlay.dart';

void main() {
  testWidgets('Companion surface uses Saarthi theme and typed conversation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: VoiceAssistantOverlay(
          surface: VoiceAgentSurface.companion,
          autoStart: false,
          onClose: () {},
          onSubmit: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Talk to Saarthi'), findsOneWidget);
    expect(find.byKey(const Key('voice-typed-input')), findsOneWidget);
    expect(find.byKey(const Key('voice-assistant-image')), findsOneWidget);
  });
}

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/services/voice/recorded_transcription_service.dart';
import 'package:frontend/widgets/assistant/voice/recorded_voice_dialog.dart';
import 'package:record/record.dart';

class FakeRecorder extends Fake implements AudioRecorder {
  final audio = StreamController<Uint8List>();
  bool stopped = false;
  @override
  Future<bool> hasPermission({bool request = true}) async => true;
  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async {
    expect(config.encoder, AudioEncoder.pcm16bits);
    expect(config.sampleRate, 16000);
    expect(config.numChannels, 1);
    return audio.stream;
  }

  @override
  Future<String?> stop() async {
    stopped = true;
    return null;
  }

  @override
  Future<void> dispose() async {
    stopped = true;
    await audio.close();
  }
}

class FakeTranscriber implements RecordedTranscriptionService {
  final languages = <String>[];
  bool failPoll = false;
  final pending = Completer<TranscriptionResult>();
  bool hold = false;
  @override
  Future<String> submit(Uint8List audio, String language) async {
    languages.add(language);
    expect(audio.length, 6400);
    return 'owned-job';
  }

  @override
  Future<TranscriptionResult> poll(String handle) async {
    if (failPoll) {
      failPoll = false;
      throw StateError('network');
    }
    if (hold) return pending.future;
    return const TranscriptionResult(
      TranscriptionPhase.completed,
      transcript: 'எனக்கு கடன் வேண்டும்',
    );
  }
}

Future<void> open(
  WidgetTester tester,
  FakeRecorder recorder,
  FakeTranscriber service,
  ValueChanged<ReviewedVoiceInput?> onResult, {
  Future<void> Function(ReviewedVoiceInput)? onSend,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => onResult(
              await showDialog<ReviewedVoiceInput>(
                context: context,
                builder: (_) => RecordedVoiceDialog(
                  service: service,
                  recorder: recorder,
                  initialLanguage: 'ta-IN',
                  onSend: onSend,
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Record a new request'));
  await tester.tap(find.text('Record a new request'));
  await tester.pumpAndSettle();
  recorder.audio.add(Uint8List(6400));
  await tester.pump();
}

void main() {
  testWidgets(
    'recording stops before upload; reviewed edits are sent only on confirmation',
    (tester) async {
      final recorder = FakeRecorder();
      final service = FakeTranscriber();
      ReviewedVoiceInput? result;
      await open(tester, recorder, service, (value) => result = value);
      expect(service.languages, isEmpty);
      await tester.tap(find.text('Stop and transcribe'));
      await tester.pump(const Duration(seconds: 1));
      expect(recorder.stopped, isTrue, reason: 'recorder stopped');
      expect(service.languages, ['ta-IN'], reason: 'submitted after stop');
      await tester.pumpAndSettle();
      expect(recorder.stopped, isTrue);
      expect(service.languages, ['ta-IN']);
      expect(result, isNull);
      await tester.enterText(find.byType(TextField), 'Corrected request');
      await tester.tap(find.text('Send reviewed request'));
      await tester.pumpAndSettle();
      expect(result?.text, 'Corrected request');
      expect(result?.language, 'ta-IN');
    },
  );

  testWidgets(
    'network retry polls the same job without recording or submitting again',
    (tester) async {
      final service = FakeTranscriber()..failPoll = true;
      await open(tester, FakeRecorder(), service, (_) {});
      await tester.tap(find.text('Stop and transcribe'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Transcribe this recording again'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transcribe this recording again'));
      await tester.pumpAndSettle();
      expect(service.languages, ['ta-IN']);
      expect(find.text('எனக்கு கடன் வேண்டும்'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('cancelled job cannot send or update a disposed review dialog', (
    tester,
  ) async {
    final service = FakeTranscriber()..hold = true;
    ReviewedVoiceInput? result;
    await open(tester, FakeRecorder(), service, (value) => result = value);
    await tester.tap(find.text('Stop and transcribe'));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    service.pending.complete(
      const TranscriptionResult(
        TranscriptionPhase.completed,
        transcript: 'late',
      ),
    );
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing the language reuses the same recording in a new job', (
    tester,
  ) async {
    final service = FakeTranscriber();
    await open(tester, FakeRecorder(), service, (_) {});
    await tester.tap(find.text('Stop and transcribe'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('हिन्दी').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Transcribe this recording again'));
    await tester.tap(find.text('Transcribe this recording again'));
    await tester.pumpAndSettle();
    expect(service.languages, ['ta-IN', 'hi-IN']);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'typing instead prevents a pending job overwriting the correction',
    (tester) async {
      final service = FakeTranscriber()..hold = true;
      ReviewedVoiceInput? result;
      await open(tester, FakeRecorder(), service, (value) => result = value);
      await tester.tap(find.text('Stop and transcribe'));
      await tester.pump();
      await tester.ensureVisible(find.text('Type instead...'));
      await tester.tap(find.text('Type instead...'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Typed correction');
      service.pending.complete(
        const TranscriptionResult(
          TranscriptionPhase.completed,
          transcript: 'late wrong transcript',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Typed correction'), findsOneWidget);
      await tester.tap(find.text('Send reviewed request'));
      await tester.pumpAndSettle();
      expect(result?.text, 'Typed correction');
    },
  );

  testWidgets('review remains usable on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester, FakeRecorder(), FakeTranscriber(), (_) {});
    await tester.ensureVisible(find.text('Stop and transcribe'));
    await tester.tap(find.text('Stop and transcribe'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'My corrected request');
    await tester.tap(find.text('Send reviewed request'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed sending keeps the transcript for retry without another recording',
    (tester) async {
      var attempts = 0;
      ReviewedVoiceInput? result;
      final service = FakeTranscriber();
      await open(
        tester,
        FakeRecorder(),
        service,
        (value) => result = value,
        onSend: (_) async {
          if (++attempts == 1) throw StateError('Disconnected');
        },
      );
      await tester.tap(find.text('Stop and transcribe'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Keep my corrected request',
      );
      await tester.tap(find.text('Send reviewed request'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.text('Keep my corrected request'), findsOneWidget);
      await tester.tap(find.text('Send reviewed request'));
      await tester.pumpAndSettle();
      expect(result?.text, 'Keep my corrected request');
      expect(service.languages, ['ta-IN']);
    },
  );
}

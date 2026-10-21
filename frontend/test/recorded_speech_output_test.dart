import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/voice/recorded_speech_output.dart';

class _Player extends Fake implements AudioPlayer {
  final completions = StreamController<void>.broadcast();
  AudioContext? context;
  double? lastVolume;
  int plays = 0;
  int stops = 0;
  @override
  Stream<void> get onPlayerComplete => completions.stream;
  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    expect(source, isA<BytesSource>());
    context = ctx;
    lastVolume = volume;
    plays++;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() => completions.close();
}

void main() {
  test(
    'each reply reapplies speech/media context after microphone capture',
    () async {
      final player = _Player();
      final output = DeviceSpeechOutput(createPlayer: () => player);
      addTearDown(output.dispose);
      for (var turn = 0; turn < 2; turn++) {
        final playing = output.play(Uint8List.fromList([1, 2]));
        await pumpEventQueue();
        expect(player.context!.android.contentType, AndroidContentType.speech);
        expect(player.context!.android.usageType, AndroidUsageType.media);
        expect(player.context!.android.audioMode, AndroidAudioMode.normal);
        expect(
          player.context!.android.audioFocus,
          AndroidAudioFocus.gainTransient,
        );
        expect(player.lastVolume, 1);
        player.completions.add(null);
        await playing;
      }
      expect(player.plays, 2);
    },
  );
  test('Pause completes pending playback and stops the player', () async {
    final player = _Player();
    final output = DeviceSpeechOutput(createPlayer: () => player);
    addTearDown(output.dispose);
    final playing = output.play(Uint8List.fromList([1, 2]));
    await pumpEventQueue();
    await output.stop();
    await playing;
    expect(player.stops, 1);
  });
}

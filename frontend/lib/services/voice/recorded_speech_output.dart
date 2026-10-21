import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

abstract interface class RecordedSpeechOutput {
  Future<void> play(Uint8List bytes);
  Future<void> stop();
  Future<void> dispose();
}

class DeviceSpeechOutput implements RecordedSpeechOutput {
  DeviceSpeechOutput({AudioPlayer Function()? createPlayer})
    : _createPlayer = createPlayer ?? AudioPlayer.new;
  final AudioPlayer Function() _createPlayer;
  AudioPlayer? _player;
  Completer<void>? _finished;
  int _generation = 0;
  @override
  Future<void> play(Uint8List bytes) async {
    final ticket = _generation;
    final player = _player ??= _createPlayer();
    final done = _finished = Completer<void>();
    final completion = player.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    try {
      await player.play(
        BytesSource(bytes, mimeType: 'audio/mpeg'),
        volume: 1,
        ctx: AudioContext(
          android: const AudioContextAndroid(
            audioMode: AndroidAudioMode.normal,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransient,
          ),
          iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
        ),
      );
      if (ticket != _generation) {
        await player.stop();
        return;
      }
      await done.future.timeout(const Duration(minutes: 3));
    } finally {
      await completion.cancel();
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    final done = _finished;
    _finished = null;
    if (done != null && !done.isCompleted) done.complete();
    await _player?.stop();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _player?.dispose();
  }
}

import 'dart:typed_data';
import 'package:record/record.dart';

abstract interface class VoiceMicrophone {
  Future<Stream<Uint8List>> start();
  Future<void> stop();
  Future<void> dispose();
}

class DeviceVoiceMicrophone implements VoiceMicrophone {
  AudioRecorder? _recorder;
  bool _recording = false;
  @override
  Future<Stream<Uint8List>> start() async {
    final recorder = _recorder ??= AudioRecorder();
    if (!await recorder.hasPermission()) throw StateError('MIC_PERMISSION');
    final stream = await recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );
    _recording = true;
    return stream;
  }

  @override
  Future<void> stop() async {
    if (!_recording) return;
    _recording = false;
    await _recorder?.stop();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _recorder?.dispose();
  }
}

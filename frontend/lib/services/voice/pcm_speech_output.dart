import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

abstract interface class PcmSpeechOutput {
  Future<void> start(int sampleRate);
  void add(Uint8List bytes);
  Future<void> finish();
  Future<void> stop();
  Future<void> dispose();
}

class DevicePcmSpeechOutput implements PcmSpeechOutput {
  static const _channel = MethodChannel('com.inschemes.app/voice_pcm');
  Future<void> _queue = Future.value();
  int _generation = 0;
  int _pending = 0;
  @override
  Future<void> start(int sampleRate) async {
    await stop();
    await _channel.invokeMethod<void>('start', {'sampleRate': sampleRate});
  }

  @override
  void add(Uint8List bytes) {
    final generation = _generation;
    _pending += bytes.length;
    if (_pending > 512000) throw StateError('VOICE_CONNECTION_SLOW');
    _queue = _queue.then((_) async {
      if (generation != _generation) return;
      try {
        await _channel.invokeMethod<void>('write', bytes);
      } finally {
        if (generation == _generation) _pending -= bytes.length;
      }
    });
    // The controller observes the same error at finish; avoid uncaught futures.
    unawaited(_queue.catchError((Object _) {}));
  }

  @override
  Future<void> finish() async {
    final generation = _generation;
    await _queue;
    if (generation == _generation) await _channel.invokeMethod<void>('drain');
  }

  @override
  Future<void> stop() async {
    ++_generation;
    _pending = 0;
    _queue = Future.value();
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await _channel.invokeMethod<void>('stop');
  }

  @override
  Future<void> dispose() => stop();
}

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../network/api_client.dart';

class LiveSpeechEvent {
  const LiveSpeechEvent(this.type, {this.text = '', this.code});
  final String type;
  final String text;
  final String? code;
}

abstract interface class RealtimeSpeechTransport {
  Stream<LiveSpeechEvent> get events;
  Future<void> connect({required String language, required int silenceMs});
  void audio(Uint8List bytes);
  void finish();
  Future<void> close();
  Future<void> dispose();
}

/// One bounded listening turn. Secrets never appear in URLs or diagnostics.
class MssRealtimeSpeechTransport implements RealtimeSpeechTransport {
  MssRealtimeSpeechTransport({ApiClient? client})
    : _client = client ?? ApiClient.instance;
  final ApiClient _client;
  final _events = StreamController<LiveSpeechEvent>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Completer<void>? _ready;
  bool _closing = false;
  int _generation = 0;
  @override
  Stream<LiveSpeechEvent> get events => _events.stream;

  @override
  Future<void> connect({
    required String language,
    required int silenceMs,
  }) async {
    await close();
    final generation = _generation;
    _closing = false;
    for (var attempt = 0; attempt < 2; attempt++) {
      final token = await _client.validAccessToken(forceRefresh: attempt > 0);
      if (_closing || generation != _generation) return;
      final base = _client.buildUri('/voice/stream');
      final uri = base.replace(scheme: base.scheme == 'https' ? 'wss' : 'ws');
      final channel = _channel = WebSocketChannel.connect(uri);
      final ready = _ready = Completer<void>();
      // Attach before awaiting the socket to consume early handshake failures.
      _subscription = channel.stream.listen(
        (raw) {
          if (generation != _generation || _closing) return;
          try {
            if (raw is! String || raw.length > 16000) {
              throw const FormatException();
            }
            final body = jsonDecode(raw);
            if (body is! Map || body['type'] is! String) {
              throw const FormatException();
            }
            final event = LiveSpeechEvent(
              body['type'] as String,
              text: body['text'] is String
                  ? (body['text'] as String).substring(
                      0,
                      (body['text'] as String).length.clamp(0, 2000),
                    )
                  : '',
              code: body['code'] as String?,
            );
            if (event.type == 'ready' && !ready.isCompleted) ready.complete();
            if (event.type == 'error' && !ready.isCompleted) {
              ready.completeError(
                StateError(event.code ?? 'VOICE_UNAVAILABLE'),
              );
            } else {
              _events.add(event);
            }
          } catch (_) {
            if (!ready.isCompleted) {
              ready.completeError(StateError('VOICE_UNAVAILABLE'));
            }
          }
        },
        onError: (Object _) {
          if (generation != _generation || _closing) return;
          if (!ready.isCompleted) {
            ready.completeError(StateError('VOICE_UNAVAILABLE'));
          }
          if (!_closing) {
            _events.add(
              const LiveSpeechEvent('error', code: 'VOICE_UNAVAILABLE'),
            );
          }
        },
        onDone: () {
          if (generation != _generation || _closing) return;
          if (!ready.isCompleted) {
            ready.completeError(StateError('VOICE_UNAVAILABLE'));
          }
          if (!_closing) {
            _events.add(
              const LiveSpeechEvent('error', code: 'VOICE_DISCONNECTED'),
            );
          }
        },
      );
      // Register the waiter immediately so no asynchronous socket error is unhandled.
      final waiting = ready.future.timeout(const Duration(seconds: 20));
      unawaited(waiting.catchError((Object _) {}));
      try {
        await channel.ready.timeout(const Duration(seconds: 10));
        if (generation != _generation || _closing) return;
        channel.sink.add(
          jsonEncode({
            'type': 'session.start',
            'access_token': token,
            'language': language,
            'silence_ms': silenceMs,
          }),
        );
        await waiting;
        return;
      } catch (error) {
        // Consume readiness even when opening itself failed first.
        if (!ready.isCompleted) ready.complete();
        await waiting.catchError((Object _) {});
        await _subscription?.cancel();
        unawaited(channel.sink.close());
        if (attempt == 0 && error.toString().contains('UNAUTHORIZED')) continue;
        rethrow;
      }
    }
  }

  @override
  void audio(Uint8List bytes) {
    if (_closing || _ready?.isCompleted != true) return;
    for (var offset = 0; offset < bytes.length; offset += 32000) {
      _channel?.sink.add(
        Uint8List.sublistView(
          bytes,
          offset,
          (offset + 32000).clamp(0, bytes.length),
        ),
      );
    }
  }

  @override
  void finish() => _channel?.sink.add(jsonEncode({'type': 'finish'}));
  @override
  Future<void> close() async {
    _closing = true;
    _generation++;
    final ready = _ready;
    _ready = null;
    if (ready != null && !ready.isCompleted) ready.complete();
    await _subscription?.cancel();
    _subscription = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) unawaited(channel.sink.close());
  }

  @override
  Future<void> dispose() async {
    await close();
    await _events.close();
  }
}

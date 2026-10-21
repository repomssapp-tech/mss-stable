import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../network/api_client.dart';

abstract interface class NativeAgentTransport {
  Stream<Object> get events;
  Future<void> connect(
    String language,
    List<Map<String, String>> history, {
    required bool skipGreeting,
  });
  void input(bool enabled);
  void audio(Uint8List bytes);
  Future<void> close();
  Future<void> dispose();
}

/// Only the authenticated MSS socket is exposed to the app. Provider signed
/// URLs, workspace keys and scheme lookup capabilities remain on the server.
class MssNativeAgentTransport implements NativeAgentTransport {
  MssNativeAgentTransport({ApiClient? client})
    : _client = client ?? ApiClient.instance;
  final ApiClient _client;
  final _events = StreamController<Object>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Completer<void>? _ready;
  int _generation = 0;
  @override
  Stream<Object> get events => _events.stream;

  @override
  Future<void> connect(
    String language,
    List<Map<String, String>> history, {
    required bool skipGreeting,
  }) async {
    await close();
    final generation = _generation;
    for (var attempt = 0; attempt < 2; attempt++) {
      final token = await _client.validAccessToken(forceRefresh: attempt > 0);
      if (generation != _generation) return;
      final base = _client.buildUri('/voice/agent');
      final channel = _channel = WebSocketChannel.connect(
        base.replace(scheme: base.scheme == 'https' ? 'wss' : 'ws'),
      );
      final ready = _ready = Completer<void>();
      var authenticated = false;
      void failure(String code) {
        if (generation != _generation) return;
        if (!ready.isCompleted) {
          ready.completeError(StateError(code));
        } else if (authenticated) {
          _events.add({'type': 'error', 'code': code});
        }
      }

      _subscription = channel.stream.listen(
        (raw) {
          if (generation != _generation) return;
          try {
            if (raw is List<int>) {
              if (raw.length > 128000 || raw.length.isOdd) {
                throw const FormatException();
              }
              _events.add(Uint8List.fromList(raw));
              return;
            }
            if (raw is! String || raw.length > 32000) {
              throw const FormatException();
            }
            final body = jsonDecode(raw);
            if (body is! Map || body['type'] is! String) {
              throw const FormatException();
            }
            if (body['type'] == 'ready' && !ready.isCompleted) {
              authenticated = true;
              ready.complete();
            } else if (body['type'] == 'error') {
              failure(
                body['code'] is String ? body['code'] : 'VOICE_UNAVAILABLE',
              );
            } else {
              _events.add(Map<String, dynamic>.from(body));
            }
          } catch (_) {
            failure('VOICE_UNAVAILABLE');
          }
        },
        onError: (Object _) => failure('VOICE_CONNECTION_LOST'),
        onDone: () => failure('VOICE_CONNECTION_LOST'),
      );
      final waiting = ready.future.timeout(const Duration(seconds: 30));
      unawaited(waiting.catchError((Object _) {}));
      try {
        await channel.ready.timeout(const Duration(seconds: 10));
        if (generation != _generation) return;
        channel.sink.add(
          jsonEncode({
            'type': 'session.start',
            'access_token': token,
            'language': language,
            'history': history,
            'skip_greeting': skipGreeting,
          }),
        );
        await waiting;
        return;
      } catch (error) {
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
  void input(bool enabled) => _channel?.sink.add(
    jsonEncode({'type': enabled ? 'input.start' : 'input.stop'}),
  );
  @override
  void audio(Uint8List bytes) {
    for (var offset = 0; offset < bytes.length; offset += 16000) {
      _channel?.sink.add(
        Uint8List.sublistView(
          bytes,
          offset,
          (offset + 16000).clamp(0, bytes.length),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    ++_generation;
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

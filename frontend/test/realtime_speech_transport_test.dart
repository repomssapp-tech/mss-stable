import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/network/api_client.dart';
import 'package:frontend/services/voice/realtime_speech_transport.dart';

class _Client extends ApiClient {
  _Client(String base) : super(baseUrl: base);
  final refreshes = <bool>[];
  @override
  Future<String> validAccessToken({bool forceRefresh = false}) async {
    refreshes.add(forceRefresh);
    return (forceRefresh ? 'b' : 'a') * 43;
  }
}

void main() {
  test(
    'browser-compatible first frame authenticates before PCM and preserves partial/final text',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final authenticated = Completer<Map<String, dynamic>>(),
          binary = Completer<List<int>>();
      final connections = <WebSocket>[];
      final serving = server.listen((request) async {
        expect(request.uri.path, '/v1/voice/stream');
        expect(request.uri.query, isEmpty);
        final socket = await WebSocketTransformer.upgrade(request);
        connections.add(socket);
        socket.listen((raw) {
          if (raw is String) {
            final body = jsonDecode(raw) as Map<String, dynamic>;
            if (body['type'] == 'session.start') {
              authenticated.complete(body);
              socket.add(jsonEncode({'type': 'ready'}));
            }
          } else {
            binary.complete(List<int>.from(raw as List));
            socket.add(
              jsonEncode({'type': 'transcript.partial', 'text': 'வணக்கம்'}),
            );
            socket.add(
              jsonEncode({'type': 'transcript.final', 'text': 'வணக்கம் உதவி'}),
            );
          }
        });
      });
      final client = _Client('http://127.0.0.1:${server.port}/v1');
      final speech = MssRealtimeSpeechTransport(client: client),
          events = <LiveSpeechEvent>[];
      final subscription = speech.events.listen(events.add);
      try {
        await speech.connect(language: 'ta', silenceMs: 1800);
        expect(await authenticated.future, {
          'type': 'session.start',
          'access_token': 'a' * 43,
          'language': 'ta',
          'silence_ms': 1800,
        });
        speech.audio(Uint8List.fromList([1, 0, 2, 0]));
        expect(await binary.future, [1, 0, 2, 0]);
        await pumpEventQueue();
        expect(
          events.where((event) => event.type == 'transcript.final').single.text,
          'வணக்கம் உதவி',
        );
        await speech.close();
        speech.audio(Uint8List.fromList([9, 9]));
      } finally {
        await subscription.cancel();
        await speech.dispose();
        for (final socket in connections) {
          await socket.close();
        }
        await serving.cancel();
        await server.close(force: true);
      }
    },
  );
  test(
    'an expired socket token refreshes once and is never placed in a URL',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var attempts = 0;
      final connections = <WebSocket>[];
      final serving = server.listen((request) async {
        expect(request.uri.query, isEmpty);
        final socket = await WebSocketTransformer.upgrade(request);
        connections.add(socket);
        socket.listen((raw) {
          final body = jsonDecode(raw as String) as Map<String, dynamic>;
          attempts++;
          if (attempts == 1) {
            socket.add(jsonEncode({'type': 'error', 'code': 'UNAUTHORIZED'}));
          } else {
            expect(body['access_token'], 'b' * 43);
            socket.add(jsonEncode({'type': 'ready'}));
          }
        });
      });
      final client = _Client('http://127.0.0.1:${server.port}/v1');
      final speech = MssRealtimeSpeechTransport(client: client);
      try {
        await speech.connect(language: 'hi', silenceMs: 1200);
        expect(attempts, 2);
        expect(client.refreshes, [false, true]);
      } finally {
        await speech.dispose();
        for (final socket in connections) {
          await socket.close();
        }
        await serving.cancel();
        await server.close(force: true);
      }
    },
  );
}

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../account/token_storage.dart';
import '../network/api_client.dart';
import '../security/app_lock_service.dart';

/// Service managing real-time notification invalidation events streamed via SSE
/// over `GET /v1/me/notifications/events`.
class SseEventService {
  SseEventService({
    ApiClient? client,
    TokenStorage? tokenStorage,
    http.Client? httpClient,
  })  : _client = client ?? ApiClient.instance,
        _tokenStorage = tokenStorage ?? TokenStorage.instance,
        _httpClient = httpClient ?? http.Client();

  final ApiClient _client;
  final TokenStorage _tokenStorage;
  final http.Client _httpClient;

  static const String _kLastEventIdKey = 'mss_sse_last_event_id';

  bool _isActive = false;
  bool get isActive => _isActive;

  Timer? _reconnectTimer;
  String? _lastHandledEventId;

  static const int _maxPermanentFailures = 5;
  int _permanentFailures = 0;

  static bool _isPermanentError(int status) =>
      status >= 400 && status < 500 && status != 408 && status != 429;

  /// Starts listening to the SSE stream. Calls [onRefetchNeeded] whenever
  /// invalidation hints or notification events arrive.
  Future<void> startListening({
    required Future<void> Function() onRefetchNeeded,
  }) async {
    if (_isActive) return;
    _isActive = true;

    // Load persisted cursor
    final prefs = await SharedPreferences.getInstance();
    _lastHandledEventId = prefs.getString(_kLastEventIdKey);

    _listenLoop(onRefetchNeeded);
  }

  /// Stops streaming and cancels any scheduled reconnect.
  void stopListening() {
    _isActive = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Clears stored cursor on sign-out or session invalidation.
  Future<void> clearCursor() async {
    _lastHandledEventId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastEventIdKey);
  }

  Future<void> _listenLoop(Future<void> Function() onRefetchNeeded) async {
    while (_isActive) {
      final token = await _tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        // Not authenticated; wait and retry or stop
        _scheduleReconnect(onRefetchNeeded, delaySeconds: 5);
        break;
      }

      final uri = _client.buildUri('/v1/me/notifications/events');
      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Authorization'] = 'Bearer $token';
      if (_lastHandledEventId != null && _lastHandledEventId!.isNotEmpty) {
        request.headers['Last-Event-ID'] = _lastHandledEventId!;
      }

      try {
        final streamedResponse = await _httpClient.send(request);

        if (streamedResponse.statusCode == 200) {
          _permanentFailures = 0;
          String? currentId;
          String? currentEvent;
          final currentDataLines = <String>[];

          final stream = streamedResponse.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter());

          await for (final line in stream) {
            if (!_isActive) break;

            if (line.isEmpty) {
              // End of an SSE frame
              if (currentEvent != null || currentDataLines.isNotEmpty) {
                await _handleSseEvent(
                  eventId: currentId,
                  eventName: currentEvent,
                  dataPayload: currentDataLines.join('\n'),
                  onRefetchNeeded: onRefetchNeeded,
                );
              }
              currentId = null;
              currentEvent = null;
              currentDataLines.clear();
            } else if (line.startsWith('id:')) {
              currentId = line.substring(3).trim();
            } else if (line.startsWith('event:')) {
              currentEvent = line.substring(6).trim();
            } else if (line.startsWith('data:')) {
              currentDataLines.add(line.substring(5).trim());
            } else if (line.startsWith(':')) {
              // Comment / heartbeat keepalive frame
            }
          }
        } else if (streamedResponse.statusCode == 423) {
          // Locked by the administrator; the app shows its locked screen.
          AppLockService.instance.reportLocked();
          stopListening();
          break;
        } else if (streamedResponse.statusCode == 401) {
          debugPrint('[SseEventService] 401 Unauthorized; stopping SSE');
          stopListening();
          break;
        } else if (streamedResponse.statusCode == 429) {
          debugPrint('[SseEventService] 429 Rate limited; reconnecting with backoff');
          _scheduleReconnect(onRefetchNeeded, delaySeconds: 10);
          break;
        } else if (_isPermanentError(streamedResponse.statusCode)) {
          // A wrong route or configuration will not fix itself: back off and
          // give up after a few attempts instead of retrying every second.
          _permanentFailures++;
          debugPrint(
            '[SseEventService] ${streamedResponse.statusCode} from stream '
            '(attempt $_permanentFailures/$_maxPermanentFailures)',
          );
          if (_permanentFailures >= _maxPermanentFailures) {
            stopListening();
          } else {
            _scheduleReconnect(
              onRefetchNeeded,
              delaySeconds: min(300, 30 * (1 << (_permanentFailures - 1))),
            );
          }
          break;
        }
      } catch (e) {
        if (_isActive) {
          debugPrint('[SseEventService] Stream connection error: $e');
        }
      }

      if (_isActive) {
        // Stream ended (e.g. server closed after 25s); reconnect with 1..5s jitter
        final jitter = 1 + Random().nextInt(4);
        await Future.delayed(Duration(seconds: jitter));
      }
    }
  }

  Future<void> _handleSseEvent({
    String? eventId,
    String? eventName,
    required String dataPayload,
    required Future<void> Function() onRefetchNeeded,
  }) async {
    final event = eventName ?? 'message';

    if (event == 'reset') {
      // 7-day expiry or server reset: clear cursor and trigger full refetch
      await clearCursor();
      await onRefetchNeeded();
      return;
    }

    if (event == 'ready' ||
        event == 'notification.created' ||
        event == 'notification.updated' ||
        event == 'notification.deleted' ||
        event == 'message') {
      // Trigger notification inbox/count refresh FIRST
      await onRefetchNeeded();

      // Persist cursor AFTER successful refetch
      if (eventId != null && eventId.isNotEmpty) {
        _lastHandledEventId = eventId;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kLastEventIdKey, eventId);
      }
    }
  }

  void _scheduleReconnect(
    Future<void> Function() onRefetchNeeded, {
    int delaySeconds = 3,
  }) {
    if (!_isActive) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_isActive) {
        _listenLoop(onRefetchNeeded);
      }
    });
  }
}

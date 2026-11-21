import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_config.dart';
import '../backend/pending_endpoints.dart';
import '../network/connectivity_service.dart';

enum AnalyticsEvent {
  sessionStart('session_start', {'launch_kind'}),
  featureOpened('feature_opened', {'feature'}),
  searchSubmitted('search_submitted', {'source', 'result_count'}),
  filterChanged('filter_changed', {'filter_key', 'enabled'}),
  schemeOpened('scheme_opened', {'scheme_id', 'entry_point', 'rank', 'fit'}),
  schemeAction('scheme_action', {'scheme_id', 'action'}),
  questionnaireStarted('questionnaire_started', {'source'}),
  questionnaireProgress('questionnaire_progress', {'field_id', 'action'}),
  questionnaireClosed('questionnaire_closed', {'outcome'}),
  questionnaireResults('questionnaire_results', {
    'good',
    'possible',
    'not_now',
  }),
  signInPrompt('sign_in_prompt', {'feature', 'action'}),
  signInCompleted('sign_in_completed', {'from_guest'}),
  profileProgress('profile_progress', {'section', 'action'}),
  profileCompleted('profile_completed', {});

  const AnalyticsEvent(this.wireName, this.allowedProperties);

  final String wireName;
  final Set<String> allowedProperties;
}

class AppAnalytics with WidgetsBindingObserver {
  AppAnalytics({
    required this.noticeVersion,
    http.Client? client,
    Uri? endpoint,
  }) : _client = client,
       _endpoint = endpoint;

  static final instance = AppAnalytics(
    noticeVersion: const bool.fromEnvironment('MSS_ANALYTICS_ENABLED')
        ? const String.fromEnvironment('MSS_ANALYTICS_NOTICE_VERSION')
        : '',
  );

  static const _storageKey = 'mss_analytics_buffer_v1';
  static const _capacity = 2000;
  static const _maxBatch = 100;
  static const _maxAge = Duration(days: 30);
  static final _random = Random.secure();

  final String noticeVersion;
  http.Client? _client;
  final Uri? _endpoint;
  late final Future<SharedPreferences> _storage =
      SharedPreferences.getInstance();
  late final Future<void> _ready = _load();
  final _events = <Map<String, Object?>>[];
  late String _installId;
  String? _sessionId;
  String? _sessionUserKind;
  DateTime? _lastActivity;
  DateTime? _retryAt;
  int _failures = 0;
  int _batchSize = _maxBatch;
  Future<void>? _inFlight;
  Timer? _timer;
  StreamSubscription<bool>? _connectivity;
  Future<void> _writes = Future<void>.value();
  Map<String, String>? Function()? _readContext;
  String _appVersion = 'unknown';

  bool get enabled => noticeVersion.isNotEmpty;

  void start(Map<String, String>? Function() readContext) {
    if (!enabled || _readContext != null) return;
    _readContext = readContext;
    WidgetsBinding.instance.addObserver(this);
    _connectivity = ConnectivityService.instance.onChanged.listen((online) {
      if (online) unawaited(flush());
    });
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(flush());
    });
    unawaited(flush());
  }

  String? interactionId() => enabled ? _id() : null;

  void endSession() {
    _sessionId = null;
    _lastActivity = null;
  }

  void track(
    AnalyticsEvent event, {
    Map<String, Object> properties = const {},
    String? interactionId,
  }) {
    final context = _readContext?.call();
    if (context == null) return;
    if (!event.allowedProperties.containsAll(properties.keys)) {
      debugPrint('[Analytics] Unsupported properties for ${event.wireName}.');
      return;
    }
    final now = DateTime.now().toUtc();
    final userKind = context['user_kind'];
    final needsSession =
        _sessionId == null ||
        _sessionUserKind != userKind ||
        now.difference(_lastActivity!) >= const Duration(minutes: 30);
    final entries = <Map<String, Object?>>[];
    if (needsSession) {
      final launch = _sessionUserKind == null ? 'cold' : 'resumed';
      _sessionId = _id();
      _sessionUserKind = userKind;
      entries.add(
        _entry(AnalyticsEvent.sessionStart, now, context, {
          'launch_kind': launch,
        }, null),
      );
    }
    _lastActivity = now;
    entries.add(_entry(event, now, context, properties, interactionId));
    _enqueue(() async {
      for (final event in entries) {
        (event['context'] as Map<String, String>)['app_version'] = _appVersion;
        _events.add(event);
      }
      _prune(now);
      await _persist();
    });
  }

  Map<String, Object?> _entry(
    AnalyticsEvent event,
    DateTime occurredAt,
    Map<String, String> context,
    Map<String, Object> properties,
    String? interactionId,
  ) => {
    'event_id': _id(),
    'session_id': _sessionId,
    'interaction_id': ?interactionId,
    'name': event.wireName,
    'occurred_at': occurredAt.toIso8601String(),
    'context': {
      ...context,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
    },
    'props': Map<String, Object>.of(properties),
  };

  Future<void> _load() async {
    final storage = await _storage;
    final raw = storage.getString(_storageKey);
    _installId = _id();
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['notice_version'] == noticeVersion) {
          _installId = data['install_id'] as String;
          _events.addAll((data['events'] as List).cast<Map<String, Object?>>());
        } else {
          await storage.remove(_storageKey);
        }
      } on FormatException {
        await storage.remove(_storageKey);
        debugPrint('[Analytics] Invalid local buffer was cleared.');
      } on TypeError {
        await storage.remove(_storageKey);
        debugPrint('[Analytics] Invalid local buffer was cleared.');
      }
    }
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
    } on Exception {
      debugPrint('[Analytics] App version unavailable.');
    }
  }

  Future<void> _persist() async {
    final saved = await (await _storage).setString(
      _storageKey,
      jsonEncode({
        'notice_version': noticeVersion,
        'install_id': _installId,
        'events': _events,
      }),
    );
    if (!saved) throw StateError('Analytics buffer could not be saved.');
  }

  void _prune(DateTime now) {
    final cutoff = now.subtract(_maxAge);
    _events.removeWhere(
      (event) =>
          DateTime.parse(event['occurred_at'] as String).isBefore(cutoff),
    );
    if (_events.length > _capacity) {
      _events.removeRange(0, _events.length - _capacity);
    }
  }

  Future<void> _enqueue(Future<void> Function() action) {
    _writes = _writes
        .then((_) async {
          await _ready;
          await action();
        })
        .catchError((Object error) {
          debugPrint('[Analytics] Local buffer write failed.');
        });
    return _writes;
  }

  Future<void> flush() {
    if (!enabled ||
        !ConnectivityService.instance.isOnline ||
        (_retryAt?.isAfter(DateTime.now()) ?? false)) {
      return Future<void>.value();
    }
    return _inFlight ??= _flush().whenComplete(() => _inFlight = null);
  }

  Future<void> _flush() async {
    try {
      await _ready;
      await _writes;
      final beforeExpiry = _events.length;
      _prune(DateTime.now().toUtc());
      if (_events.length != beforeExpiry) await _enqueue(_persist);
      if (_events.isEmpty) return;
      final batch = _events.take(_batchSize).toList(growable: false);
      final endpoint =
          _endpoint ??
          Uri.parse('${AppConfig.apiV1Url}${PendingEndpoints.analyticsEvents}');
      final client = _client ??= http.Client();
      final response = await client
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'schema_version': 1,
              'notice_version': noticeVersion,
              'install_id': _installId,
              'events': batch,
            }),
          )
          .timeout(const Duration(seconds: 20));
      final code = response.statusCode;
      if (code == 200) {
        final ack = jsonDecode(response.body);
        if (ack is! Map ||
            ack['accepted'] is! int ||
            ack['duplicates'] is! int ||
            (ack['accepted'] as int) < 0 ||
            (ack['duplicates'] as int) < 0 ||
            (ack['accepted'] as int) + (ack['duplicates'] as int) !=
                batch.length) {
          throw const FormatException('Unexpected analytics acknowledgment.');
        }
      }
      if (code == 413 && batch.length > 1) {
        _batchSize = max(1, batch.length ~/ 2);
        return;
      }
      if (code == 200 ||
          code == 400 ||
          code == 409 ||
          code == 413 ||
          code == 422) {
        if (code != 200) debugPrint('[Analytics] Batch rejected (HTTP $code).');
        final sent = batch.map((event) => event['event_id']).toSet();
        await _enqueue(() async {
          _events.removeWhere((event) => sent.contains(event['event_id']));
          await _persist();
        });
        _failures = 0;
        _retryAt = null;
      } else {
        _backoff(response.headers['retry-after']);
        debugPrint('[Analytics] Batch deferred (HTTP $code).');
      }
    } on Exception {
      _backoff(null);
      debugPrint('[Analytics] Batch deferred.');
    }
  }

  void _backoff(String? retryAfter) {
    final minutes = switch (_failures++) {
      0 => 1,
      1 => 5,
      _ => 30,
    };
    final now = DateTime.now();
    final minimum = now.add(Duration(minutes: minutes));
    final seconds = int.tryParse(retryAfter ?? '');
    final retryDate = seconds == null
        ? null
        : now.add(Duration(seconds: max(0, seconds)));
    _retryAt = retryDate != null && retryDate.isAfter(minimum)
        ? retryDate
        : minimum;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.resumed) {
      unawaited(flush());
    }
  }

  Future<void> close() async {
    WidgetsBinding.instance.removeObserver(this);
    await _connectivity?.cancel();
    _timer?.cancel();
    await _inFlight;
    _client?.close();
    await _writes;
  }

  static String _id() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

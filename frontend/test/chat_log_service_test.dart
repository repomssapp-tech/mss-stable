import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/chat_log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatLogService Tests', () {
    late ChatLogService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = ChatLogService(conversationUid: 'test-session-12345');
    });

    test('initializes with specified or generated conversation UID', () {
      expect(service.conversationUid, 'test-session-12345');
      expect(service.messageCount, 0);
      expect(service.isFlushed, isFalse);

      final autoService = ChatLogService();
      expect(autoService.conversationUid, isNotEmpty);
      expect(autoService.conversationUid, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    });

    test('upserts messages by ID without creating streaming duplicates', () {
      service.upsertMessage(
        id: 'msg-1',
        speaker: ChatMessageSpeaker.user,
        text: 'Hello',
      );
      expect(service.messageCount, 1);

      // Delta update with same ID
      service.upsertMessage(
        id: 'msg-1',
        speaker: ChatMessageSpeaker.user,
        text: 'Hello, what schemes are available?',
      );
      expect(service.messageCount, 1);

      final sessionRow = service.buildSessionRow(mode: 'voice', userId: 'test-user');
      final transcript = sessionRow['transcript'] as List;
      expect(transcript.length, 1);
      expect(transcript.first['text'], 'Hello, what schemes are available?');
    });

    test('pairs standard alternating user and assistant turns', () {
      service.recordUserMessage('What schemes are there for farmers?', id: 'u1');
      service.recordAiMessage('PM-KISAN and Uzhavar Pathukappu are available.', id: 'a1');
      service.recordUserMessage('How do I apply for PM-KISAN?', id: 'u2');
      service.recordAiMessage('You can apply online with land documents.', id: 'a2');

      final sessionRow = service.buildSessionRow(mode: 'voice', userId: 'test-user');
      final transcript = sessionRow['transcript'] as List;

      expect(transcript.length, 4);
      expect(transcript[0]['turn'], 1);
      expect(transcript[0]['role'], 'user');
      expect(transcript[0]['text'], 'What schemes are there for farmers?');
      
      expect(transcript[1]['turn'], 1);
      expect(transcript[1]['role'], 'ai');
      expect(transcript[1]['text'], 'PM-KISAN and Uzhavar Pathukappu are available.');

      expect(transcript[2]['turn'], 2);
      expect(transcript[2]['role'], 'user');
      expect(transcript[2]['text'], 'How do I apply for PM-KISAN?');

      expect(transcript[3]['turn'], 2);
      expect(transcript[3]['role'], 'ai');
      expect(transcript[3]['text'], 'You can apply online with land documents.');
    });

    test('preserves the real per-turn timestamp so duration is not always 0', () {
      final start = DateTime.utc(2026, 9, 5, 10, 0, 0);
      service.upsertMessage(
        id: 'u1',
        speaker: ChatMessageSpeaker.user,
        text: 'What schemes are there for farmers?',
        timestamp: start,
      );
      service.upsertMessage(
        id: 'a1',
        speaker: ChatMessageSpeaker.assistant,
        text: 'PM-KISAN is available.',
        timestamp: start.add(const Duration(seconds: 45)),
      );

      final sessionRow = service.buildSessionRow(mode: 'voice', userId: 'test-user');
      final metrics = sessionRow['session_metrics'] as Map;

      expect(metrics['total_duration_sec'], 45);
    });

    test('handles assistant greeting first', () {
      service.recordAiMessage('Vanakkam! I am Saarthi, your welfare assistant.', id: 'a0');
      service.recordUserMessage('Tell me about scholarships.', id: 'u1');
      service.recordAiMessage('Post-Matric scholarship is available for college students.', id: 'a1');

      final sessionRow = service.buildSessionRow(mode: 'voice', userId: 'test-user');
      final transcript = sessionRow['transcript'] as List;

      expect(transcript.length, 3);
      expect(transcript[0]['turn'], 1);
      expect(transcript[0]['role'], 'ai');
      expect(transcript[0]['text'], 'Vanakkam! I am Saarthi, your welfare assistant.');

      expect(transcript[1]['turn'], 2);
      expect(transcript[1]['role'], 'user');
      expect(transcript[1]['text'], 'Tell me about scholarships.');
    });

    test('handles user abrupt exit gracefully', () {
      service.recordUserMessage('I want to apply for agriculture loan.', id: 'u1');

      final sessionRow = service.buildSessionRow(mode: 'voice', userId: 'test-user');
      final transcript = sessionRow['transcript'] as List;

      expect(transcript.length, 1);
      expect(transcript[0]['turn'], 1);
      expect(transcript[0]['role'], 'user');
      expect(transcript[0]['text'], 'I want to apply for agriculture loan.');
      expect(sessionRow['status'], 'completed');
    });

    test('maintains separate turns for consecutive user speech', () {
      service.recordUserMessage('I am 22 years old.', id: 'u1');
      service.recordUserMessage('And I need business funding.', id: 'u2');
      service.recordAiMessage('PMEGP scheme provides loan subsidy for young entrepreneurs.', id: 'a1');

      final sessionRow = service.buildSessionRow(mode: 'voice', userId: 'test-user');
      final transcript = sessionRow['transcript'] as List;

      expect(transcript.length, 3);
      expect(transcript[0]['turn'], 1);
      expect(transcript[0]['role'], 'user');
      expect(transcript[0]['text'], 'I am 22 years old.');

      expect(transcript[1]['turn'], 2);
      expect(transcript[1]['role'], 'user');
      expect(transcript[1]['text'], 'And I need business funding.');

      expect(transcript[2]['turn'], 2);
      expect(transcript[2]['role'], 'ai');
      expect(transcript[2]['text'], 'PMEGP scheme provides loan subsidy for young entrepreneurs.');
    });

    test('empty conversation produces empty session row and no writes', () async {
      final sessionRow = service.buildSessionRow(mode: 'voice', userId: 'test-user');
      expect(sessionRow, isEmpty);

      final flushed = await service.flushSessionLogs(mode: 'voice', userId: 'test-user');
      expect(flushed, isFalse);
      expect(service.isFlushed, isTrue);
    });

    test('idempotency latch prevents double submission', () async {
      service.recordUserMessage('Hello', id: 'u1');
      service.recordAiMessage('Hi', id: 'a1');

      // First flush
      await service.flushSessionLogs(mode: 'voice', userId: 'test-user');
      expect(service.isFlushed, isTrue);

      // Second flush attempt
      final secondFlush = await service.flushSessionLogs(mode: 'voice', userId: 'test-user');
      expect(secondFlush, isFalse);
    });

    test('ChatPayloadMapper emits strictly required Supabase keys', () {
      service.recordUserMessage('Hello Saarthi', id: 'u1');
      service.recordAiMessage('Vanakkam!', id: 'a1');

      final row = service.buildSessionRow(
        mode: 'voice',
        baseMetadata: {'source': 'companion_mode'},
        userId: 'test-user',
      );

      // Verify ONLY the exact expected keys exist
      const expectedKeys = {
        'session_id',
        'user_id',
        'status',
        'transcript',
        'session_metrics',
        'created_at',
        'ended_at',
      };
      expect(row.keys.toSet(), equals(expectedKeys));
      
      expect(row['session_id'], 'test-session-12345');
      expect(row['user_id'], 'test-user');
      expect(row['status'], 'completed');
      expect(row['session_metrics']['metadata'], {'source': 'companion_mode'});
      
      final transcript = row['transcript'] as List;
      expect(transcript.length, 2);
      // 'Hello Saarthi' is Latin script → detected as English
      expect((transcript[0] as Map)['detected_language'], 'en');
    });

    test('syncChatSession method delegates and preserves local cache when offline', () async {
      final prefs = await SharedPreferences.getInstance();
      final syncService = ChatLogService(conversationUid: 'offline-sess-1');

      syncService.recordUserMessage('Tell me about farming loan', id: 'u1');
      syncService.recordAiMessage('NABARD schemes are available', id: 'a1');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Local storage must contain the pending session before sync
      final pendingBefore = prefs.getStringList('chat_log_pending_sessions');
      expect(pendingBefore, contains('offline-sess-1'));
      expect(prefs.containsKey('chat_log_session_offline-sess-1'), isTrue);

      // Calling syncChatSession with no client simulates unavailable Supabase
      final success = await syncService.syncChatSession(mode: 'voice', userId: 'test-user');
      expect(success, isFalse);

      // CRITICAL RULE: local cache must remain intact for future recovery!
      final pendingAfter = prefs.getStringList('chat_log_pending_sessions');
      expect(pendingAfter, contains('offline-sess-1'));
      expect(prefs.containsKey('chat_log_session_offline-sess-1'), isTrue);
    });
    test('AI messages correctly map recommendations to JSON and user messages omit it entirely', () {
      service.recordUserMessage('Tell me about farming loan', id: 'u1');
      service.recordAiMessage(
        'NABARD schemes are available',
        id: 'a1',
        recommendations: ['NABARD Scheme A', 'NABARD Scheme B'],
      );
      service.recordUserMessage('How to apply?', id: 'u2');
      service.recordAiMessage(
        'You can apply online.',
        id: 'a2',
        // No recommendations provided for follow-up
      );

      final sessionRow = service.buildSessionRow(mode: 'voice', userId: 'test-user');
      final transcript = sessionRow['transcript'] as List;

      expect(transcript.length, 4);

      // User turn 1
      expect(transcript[0]['role'], 'user');
      expect(transcript[0].containsKey('recommendations'), isFalse); // Users MUST NOT have this key

      // AI turn 1 with recommendations
      expect(transcript[1]['role'], 'ai');
      expect(transcript[1]['recommendations'], isA<List>());
      expect((transcript[1]['recommendations'] as List).length, 2);
      expect((transcript[1]['recommendations'] as List).contains('NABARD Scheme A'), isTrue);

      // User turn 2
      expect(transcript[2]['role'], 'user');
      expect(transcript[2].containsKey('recommendations'), isFalse);

      // AI turn 2 without recommendations
      expect(transcript[3]['role'], 'ai');
      expect(transcript[3]['recommendations'], isFalse); // AI MUST have it explicitly set to false if empty
    });
  });
}

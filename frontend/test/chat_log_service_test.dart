import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/chat_log_service.dart';

void main() {
  group('ChatLogService Tests', () {
    late ChatLogService service;

    setUp(() {
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

      final turns = service.buildTurns(mode: 'voice');
      expect(turns.length, 1);
      expect(turns.first['user_message'], 'Hello, what schemes are available?');
    });

    test('pairs standard alternating user and assistant turns', () {
      service.recordUserMessage('What schemes are there for farmers?', id: 'u1');
      service.recordAiMessage('PM-KISAN and Uzhavar Pathukappu are available.', id: 'a1');
      service.recordUserMessage('How do I apply for PM-KISAN?', id: 'u2');
      service.recordAiMessage('You can apply online with land documents.', id: 'a2');

      final turns = service.buildTurns(mode: 'voice');

      expect(turns.length, 2);
      expect(turns[0]['turn_index'], 1);
      expect(turns[0]['conversation_uid'], 'test-session-12345');
      expect(turns[0]['mode'], 'voice');
      expect(turns[0]['user_message'], 'What schemes are there for farmers?');
      expect(turns[0]['ai_message'], 'PM-KISAN and Uzhavar Pathukappu are available.');

      expect(turns[1]['turn_index'], 2);
      expect(turns[1]['conversation_uid'], 'test-session-12345');
      expect(turns[1]['mode'], 'voice');
      expect(turns[1]['user_message'], 'How do I apply for PM-KISAN?');
      expect(turns[1]['ai_message'], 'You can apply online with land documents.');
    });

    test('handles assistant greeting first with (Session started)', () {
      service.recordAiMessage('Vanakkam! I am Saarthi, your welfare assistant.', id: 'a0');
      service.recordUserMessage('Tell me about scholarships.', id: 'u1');
      service.recordAiMessage('Post-Matric scholarship is available for college students.', id: 'a1');

      final turns = service.buildTurns(mode: 'voice');

      expect(turns.length, 2);
      expect(turns[0]['turn_index'], 1);
      expect(turns[0]['user_message'], '(Session started)');
      expect(turns[0]['ai_message'], 'Vanakkam! I am Saarthi, your welfare assistant.');

      expect(turns[1]['turn_index'], 2);
      expect(turns[1]['user_message'], 'Tell me about scholarships.');
      expect(turns[1]['ai_message'], 'Post-Matric scholarship is available for college students.');
    });

    test('handles user abrupt exit without AI reply with (Session ended)', () {
      service.recordUserMessage('I want to apply for agriculture loan.', id: 'u1');

      final turns = service.buildTurns(mode: 'voice');

      expect(turns.length, 1);
      expect(turns[0]['turn_index'], 1);
      expect(turns[0]['user_message'], 'I want to apply for agriculture loan.');
      expect(turns[0]['ai_message'], '(Session ended)');
    });

    test('combines consecutive user speech into one turn', () {
      service.recordUserMessage('I am 22 years old.', id: 'u1');
      service.recordUserMessage('And I need business funding.', id: 'u2');
      service.recordAiMessage('PMEGP scheme provides loan subsidy for young entrepreneurs.', id: 'a1');

      final turns = service.buildTurns(mode: 'voice');

      expect(turns.length, 1);
      expect(turns[0]['turn_index'], 1);
      expect(turns[0]['user_message'], 'I am 22 years old. And I need business funding.');
      expect(turns[0]['ai_message'], 'PMEGP scheme provides loan subsidy for young entrepreneurs.');
    });

    test('empty conversation produces empty turns and no writes', () async {
      final turns = service.buildTurns(mode: 'voice');
      expect(turns, isEmpty);

      final flushed = await service.flushSessionLogs(mode: 'voice');
      expect(flushed, isFalse);
      expect(service.isFlushed, isTrue);
    });

    test('enforces mode check to voice or text', () {
      service.recordUserMessage('Test message', id: 'u1');
      service.recordAiMessage('Test response', id: 'a1');

      final voiceTurns = service.buildTurns(mode: 'voice');
      expect(voiceTurns.first['mode'], 'voice');

      final textTurns = service.buildTurns(mode: 'text');
      expect(textTurns.first['mode'], 'text');

      // Any unexpected mode defaults safely to voice
      final unknownTurns = service.buildTurns(mode: 'unknown');
      expect(unknownTurns.first['mode'], 'voice');
    });

    test('idempotency latch prevents double submission', () async {
      service.recordUserMessage('Hello', id: 'u1');
      service.recordAiMessage('Hi', id: 'a1');

      // First flush
      await service.flushSessionLogs(mode: 'voice');
      expect(service.isFlushed, isTrue);

      // Second flush attempt
      final secondFlush = await service.flushSessionLogs(mode: 'voice');
      expect(secondFlush, isFalse);
    });
  });
}

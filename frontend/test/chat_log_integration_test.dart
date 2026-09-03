import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/services/chat_log_service.dart';

class _RealNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  HttpOverrides.global = _RealNetworkHttpOverrides();

  const supabaseUrl = 'https://houpzsxmwemoztpuigmo.supabase.co';
  const supabaseKey = 'sb_publishable_SwlgaGsCt5N-97WwEq7tQw_aNT25VUI';

  group('Live Supabase Chat Logging Integration Test', () {
    late SupabaseClient client;
    final testConversationUid = 'test-e2e-${DateTime.now().millisecondsSinceEpoch}';

    setUpAll(() {
      client = SupabaseClient(supabaseUrl, supabaseKey);
    });

    tearDownAll(() async {
      try {
        await client
            .from('chat_logs')
            .delete()
            .eq('conversation_uid', testConversationUid);
        // ignore: avoid_print
        print('[Test Cleanup] Successfully removed test rows for $testConversationUid');
      } catch (e) {
        // ignore: avoid_print
        print('[Test Cleanup] Note: Cleanup error (non-fatal): $e');
      }
    });

    test('performs live end-to-end chat logging into Supabase chat_logs table', () async {
      final service = ChatLogService(conversationUid: testConversationUid);

      // Turn 1: AI Greeting
      service.recordAiMessage(
        'வணக்கம்! நான் சாரதி, உங்கள் நலத்திட்ட வழிகாட்டி.',
        id: 'ai-greeting',
      );

      // Turn 2: User Question + Saarthi Answer
      service.recordUserMessage(
        'விவசாயிகளுக்கு என்னென்ன திட்டங்கள் உள்ளன?',
        id: 'user-q1',
      );
      service.recordAiMessage(
        'PM-KISAN மற்றும் உழவர் பாதுகாப்பு திட்டம் உள்ளது.',
        id: 'ai-a1',
      );

      // Turn 3: User Follow-up + Saarthi Answer
      service.recordUserMessage(
        'விண்ணப்பிப்பது எப்படி?',
        id: 'user-q2',
      );
      service.recordAiMessage(
        'நீங்கள் ஆன்லைனில் அல்லது VAO அலுவலகத்தில் விண்ணப்பிக்கலாம்.',
        id: 'ai-a2',
      );

      expect(service.messageCount, 5);

      // Verify turns built in memory before flush
      final turns = service.buildTurns(
        mode: 'voice',
        baseMetadata: {'test_suite': 'e2e_verification', 'surface': 'voice_overlay'},
      );
      expect(turns.length, 3);
      expect(turns[0]['turn_index'], 1);
      expect(turns[0]['user_message'], '(Session started)');
      expect(turns[0]['ai_message'], 'வணக்கம்! நான் சாரதி, உங்கள் நலத்திட்ட வழிகாட்டி.');

      expect(turns[1]['turn_index'], 2);
      expect(turns[1]['user_message'], 'விவசாயிகளுக்கு என்னென்ன திட்டங்கள் உள்ளன?');
      expect(turns[1]['ai_message'], 'PM-KISAN மற்றும் உழவர் பாதுகாப்பு திட்டம் உள்ளது.');

      expect(turns[2]['turn_index'], 3);
      expect(turns[2]['user_message'], 'விண்ணப்பிப்பது எப்படி?');
      expect(turns[2]['ai_message'], 'நீங்கள் ஆன்லைனில் அல்லது VAO அலுவலகத்தில் விண்ணப்பிக்கலாம்.');

      // Flush to live Supabase database
      final flushResult = await service.flushSessionLogs(
        mode: 'voice',
        client: client,
        metadata: {'test_suite': 'e2e_verification', 'surface': 'voice_overlay'},
      );
      expect(flushResult, isTrue);
      expect(service.isFlushed, isTrue);

      // Idempotency: Attempt second flush, must return false without duplicate inserts
      final secondFlush = await service.flushSessionLogs(
        mode: 'voice',
        client: client,
      );
      expect(secondFlush, isFalse);

      // Query live Supabase table directly to verify stored records
      final response = await client
          .from('chat_logs')
          .select()
          .eq('conversation_uid', testConversationUid)
          .order('turn_index', ascending: true);

      final rows = List<Map<String, dynamic>>.from(response as List);
      expect(rows.length, 3);

      // Validate Row 1
      expect(rows[0]['conversation_uid'], testConversationUid);
      expect(rows[0]['turn_index'], 1);
      expect(rows[0]['mode'], 'voice');
      expect(rows[0]['user_message'], '(Session started)');
      expect(rows[0]['ai_message'], 'வணக்கம்! நான் சாரதி, உங்கள் நலத்திட்ட வழிகாட்டி.');
      expect(rows[0]['created_at'], isNotNull);

      // Validate Row 2
      expect(rows[1]['conversation_uid'], testConversationUid);
      expect(rows[1]['turn_index'], 2);
      expect(rows[1]['mode'], 'voice');
      expect(rows[1]['user_message'], 'விவசாயிகளுக்கு என்னென்ன திட்டங்கள் உள்ளன?');
      expect(rows[1]['ai_message'], 'PM-KISAN மற்றும் உழவர் பாதுகாப்பு திட்டம் உள்ளது.');

      // Validate Row 3
      expect(rows[2]['conversation_uid'], testConversationUid);
      expect(rows[2]['turn_index'], 3);
      expect(rows[2]['mode'], 'voice');
      expect(rows[2]['user_message'], 'விண்ணப்பிப்பது எப்படி?');
      expect(rows[2]['ai_message'], 'நீங்கள் ஆன்லைனில் அல்லது VAO அலுவலகத்தில் விண்ணப்பிக்கலாம்.');

      // ignore: avoid_print
      print('\n[E2E Verification Success] Verified 3 live rows in Supabase:');
      for (final r in rows) {
        // ignore: avoid_print
        print('  Turn ${r['turn_index']}: "${r['user_message']}" -> "${r['ai_message']}"');
      }
    });
  });
}

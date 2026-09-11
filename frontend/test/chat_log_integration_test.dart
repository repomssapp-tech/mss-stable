import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/services/chat/chat_log_service.dart';

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
  const supabaseKey = 'sb_publishable_GnJpz6ZxuGeeroG92VkbBA_b3_pyTvN';

  // Skipped since 20260906: voice_chat_sessions no longer accepts anonymous
  // writes. INSERT is granted to `authenticated` only and the RLS policy
  // requires user_id = auth.uid(), so this cannot pass with a publishable key
  // alone -- it needs a real signed-in session.
  //
  // To re-enable: sign a test user in during setUpAll (auth.signInWithPassword)
  // and pass that user's id through, then remove the skip below.
  // Do NOT re-add an anon INSERT grant to make this test pass.
  group('Live Supabase Chat Logging Integration Test',
      skip: 'Needs an authenticated Supabase session; anon INSERT revoked (20260906).',
      () {
    late SupabaseClient client;
    final testConversationUid = ChatLogService.generateUuidV4();

    setUpAll(() {
      client = SupabaseClient(supabaseUrl, supabaseKey);
    });

    tearDownAll(() async {
      try {
        await client
            .from('voice_chat_sessions')
            .delete()
            .eq('session_id', testConversationUid);
        // ignore: avoid_print
        print('[Test Cleanup] Successfully removed test rows for $testConversationUid');
      } catch (e) {
        // ignore: avoid_print
        print('[Test Cleanup] Note: Cleanup error (non-fatal): $e');
      }
    });

    test('performs live end-to-end chat logging into Supabase voice_chat_sessions table', () async {
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

      // Verify row built in memory before flush
      final sessionRow = service.buildSessionRow(
        mode: 'voice',
        baseMetadata: {'test_suite': 'e2e_verification', 'surface': 'voice_overlay'},
      );
      
      final transcript = sessionRow['transcript'] as List;
      expect(transcript.length, 5);
      
      expect(transcript[0]['turn'], 1);
      expect(transcript[0]['role'], 'ai');
      expect(transcript[0]['text'], 'வணக்கம்! நான் சாரதி, உங்கள் நலத்திட்ட வழிகாட்டி.');

      expect(transcript[1]['turn'], 2);
      expect(transcript[1]['role'], 'user');
      expect(transcript[1]['text'], 'விவசாயிகளுக்கு என்னென்ன திட்டங்கள் உள்ளன?');

      expect(transcript[2]['turn'], 2);
      expect(transcript[2]['role'], 'ai');
      expect(transcript[2]['text'], 'PM-KISAN மற்றும் உழவர் பாதுகாப்பு திட்டம் உள்ளது.');

      expect(transcript[3]['turn'], 3);
      expect(transcript[3]['role'], 'user');
      expect(transcript[3]['text'], 'விண்ணப்பிப்பது எப்படி?');

      expect(transcript[4]['turn'], 3);
      expect(transcript[4]['role'], 'ai');
      expect(transcript[4]['text'], 'நீங்கள் ஆன்லைனில் அல்லது VAO அலுவலகத்தில் விண்ணப்பிக்கலாம்.');

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
          .from('voice_chat_sessions')
          .select()
          .eq('session_id', testConversationUid)
          .maybeSingle();

      expect(response, isNotNull);
      final row = response!;

      expect(row['session_id'], testConversationUid);
      expect(row['status'], 'completed');
      expect(row['created_at'], isNotNull);
      expect(row['ended_at'], isNotNull);

      final dbTranscript = row['transcript'] as List;
      expect(dbTranscript.length, 5);
      expect(dbTranscript[0]['text'], 'வணக்கம்! நான் சாரதி, உங்கள் நலத்திட்ட வழிகாட்டி.');
      expect(dbTranscript[1]['text'], 'விவசாயிகளுக்கு என்னென்ன திட்டங்கள் உள்ளன?');
      expect(dbTranscript[2]['text'], 'PM-KISAN மற்றும் உழவர் பாதுகாப்பு திட்டம் உள்ளது.');
      expect(dbTranscript[3]['text'], 'விண்ணப்பிப்பது எப்படி?');
      expect(dbTranscript[4]['text'], 'நீங்கள் ஆன்லைனில் அல்லது VAO அலுவலகத்தில் விண்ணப்பிக்கலாம்.');

      final metrics = row['session_metrics'];
      expect(metrics['session_ended_type'], 'completed');
      expect(metrics['total_turns'], 3);
      expect(metrics['metadata']['test_suite'], 'e2e_verification');

      // ignore: avoid_print
      print('\n[E2E Verification Success] Verified 1 live session row in Supabase:');
      for (final msg in dbTranscript) {
        // ignore: avoid_print
        print('  Turn ${msg['turn']} [${msg['role']}]: "${msg['text']}"');
      }
    });
  });
}

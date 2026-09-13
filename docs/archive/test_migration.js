const assert = require('assert');

function detectLanguage(text) {
  if (!text) return 'en';
  for (const char of text) {
    const code = char.codePointAt(0);
    if (code >= 0x0b80 && code <= 0x0bff) return 'ta';
  }
  return 'en';
}

function transformLogs(allLogs) {
  const groups = {};
  for (const row of allLogs) {
    if (!groups[row.conversation_uid]) {
      groups[row.conversation_uid] = [];
    }
    groups[row.conversation_uid].push(row);
  }

  const newSessions = [];

  for (const [conversation_uid, rows] of Object.entries(groups)) {
    rows.sort((a, b) => a.turn_index - b.turn_index);
    
    let status = 'interrupted';
    let endedAt = null;
    let maxTurnIndex = 0;
    const transcript = [];
    let userId = null;

    for (const row of rows) {
      if (row.user_id && !userId) {
        userId = row.user_id; 
      }
      
      if (row.turn_index > maxTurnIndex) {
        maxTurnIndex = row.turn_index;
      }

      if (row.user_message && row.user_message.trim() !== '' && row.user_message !== '(Session started)') {
        transcript.push({
          turn: row.turn_index,
          role: 'user',
          text: row.user_message.trim(),
          timestamp: row.created_at,
          detected_language: detectLanguage(row.user_message),
        });
      }

      if (row.ai_message && row.ai_message.trim() !== '') {
        if (row.ai_message === '(Session ended)') {
          status = 'completed';
          endedAt = row.created_at;
        } else {
          transcript.push({
            turn: row.turn_index,
            role: 'ai',
            text: row.ai_message.trim(),
            timestamp: row.created_at,
            token_usage_ai: 0,
            interrupted_by_user: false,
          });
        }
      }
    }
    
    const sessionCreatedAt = rows[0].created_at;
    const sessionEndedAt = endedAt || rows[rows.length - 1].created_at;
    const startMs = new Date(sessionCreatedAt).getTime();
    const endMs = new Date(sessionEndedAt).getTime();
    const durationSec = Math.max(0, Math.round((endMs - startMs) / 1000));

    newSessions.push({
      session_id: conversation_uid,
      user_id: userId,
      status: status,
      transcript: transcript,
      session_metrics: {
        total_duration_sec: durationSec,
        total_turns: maxTurnIndex,
        session_ended_type: status,
      },
      created_at: sessionCreatedAt,
      ended_at: sessionEndedAt,
    });
  }
  return newSessions;
}

// MOCK DATA
const mockLogs = [
  // Session 1: completed, English, duration 120s
  { conversation_uid: '3dfb401f-c5a2-4722-b1ec-d2c3e8793c93', turn_index: 0, user_message: '(Session started)', ai_message: 'Hello', created_at: '2026-09-01T10:00:00Z', user_id: '9ae46619-121d-417e-a9aa-dbefe1dde687' },
  { conversation_uid: '3dfb401f-c5a2-4722-b1ec-d2c3e8793c93', turn_index: 1, user_message: 'What are the schemes for MSME?', ai_message: 'Here are MSME schemes', created_at: '2026-09-01T10:01:00Z', user_id: '9ae46619-121d-417e-a9aa-dbefe1dde687' },
  { conversation_uid: '3dfb401f-c5a2-4722-b1ec-d2c3e8793c93', turn_index: 2, user_message: 'Thank you', ai_message: '(Session ended)', created_at: '2026-09-01T10:02:00Z', user_id: '9ae46619-121d-417e-a9aa-dbefe1dde687' },
  
  // Session 2: interrupted, Tamil, guest (user_id null)
  { conversation_uid: 'de04d1b6-c852-42d0-aa21-10d6be2c119a', turn_index: 1, user_message: 'வணக்கம்', ai_message: 'வணக்கம்! நான் சாரதி.', created_at: '2026-09-01T11:00:30Z', user_id: null },
  { conversation_uid: 'de04d1b6-c852-42d0-aa21-10d6be2c119a', turn_index: 0, user_message: '(Session started)', ai_message: 'Vanakkam', created_at: '2026-09-01T11:00:00Z', user_id: null },
];

try {
  const result = transformLogs(mockLogs);
  
  assert.strictEqual(result.length, 2);

  // Verify Session 1
  const s1 = result.find(s => s.session_id === '3dfb401f-c5a2-4722-b1ec-d2c3e8793c93');
  assert.strictEqual(s1.status, 'completed');
  assert.strictEqual(s1.ended_at, '2026-09-01T10:02:00Z');
  assert.strictEqual(s1.session_metrics.total_duration_sec, 120);
  assert.strictEqual(s1.session_metrics.total_turns, 2);
  assert.strictEqual(s1.user_id, '9ae46619-121d-417e-a9aa-dbefe1dde687');
  assert.strictEqual(s1.transcript[1].detected_language, 'en');

  // Verify Session 2
  const s2 = result.find(s => s.session_id === 'de04d1b6-c852-42d0-aa21-10d6be2c119a');
  assert.strictEqual(s2.status, 'interrupted');
  assert.strictEqual(s2.user_id, null);
  assert.strictEqual(s2.session_metrics.total_duration_sec, 30);
  assert.strictEqual(s2.transcript[1].detected_language, 'ta');
  
  console.log('✅ ALL TESTS PASSED: test_migration.js verified successfully!');
} catch (e) {
  console.error('❌ TEST FAILED:', e);
  process.exit(1);
}

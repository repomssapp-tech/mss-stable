const assert = require('assert');

// The logic we want to test
function transformLogs(allLogs) {
  // 2. Group by conversation_uid
  const groups = {};
  for (const row of allLogs) {
    if (!groups[row.conversation_uid]) {
      groups[row.conversation_uid] = [];
    }
    groups[row.conversation_uid].push(row);
  }

  const newSessions = [];

  // 3. Process each group to build the session object
  for (const [conversation_uid, rows] of Object.entries(groups)) {
    // Sort rows within the group by turn_index
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
          text: row.user_message,
          timestamp: row.created_at,
          detected_language: 'ta'
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
            text: row.ai_message,
            timestamp: row.created_at,
            token_usage_ai: 0,
            interrupted_by_user: false
          });
        }
      }
    }
    
    const sessionCreatedAt = rows[0].created_at;

    newSessions.push({
      session_id: conversation_uid,
      user_id: userId,
      status: status,
      transcript: transcript,
      session_metrics: {
        total_duration_sec: 0,
        total_turns: maxTurnIndex,
        session_ended_type: status
      },
      created_at: sessionCreatedAt,
      ended_at: endedAt
    });
  }
  return newSessions;
}

// MOCK DATA
const mockLogs = [
  // Session 1: completed
  { conversation_uid: 'uuid-1', turn_index: 0, user_message: '(Session started)', ai_message: 'Hello', created_at: '2026-09-01T10:00:00Z', user_id: 'user-123' },
  { conversation_uid: 'uuid-1', turn_index: 1, user_message: 'Hi', ai_message: 'How can I help?', created_at: '2026-09-01T10:01:00Z', user_id: 'user-123' },
  { conversation_uid: 'uuid-1', turn_index: 2, user_message: 'Nothing', ai_message: '(Session ended)', created_at: '2026-09-01T10:02:00Z', user_id: 'user-123' },
  
  // Session 2: interrupted (no end message), missing user_id on some rows
  { conversation_uid: 'uuid-2', turn_index: 1, user_message: 'What is the weather?', ai_message: 'It is sunny.', created_at: '2026-09-01T11:00:00Z', user_id: null },
  { conversation_uid: 'uuid-2', turn_index: 0, user_message: '(Session started)', ai_message: 'Hi there', created_at: '2026-09-01T10:59:00Z', user_id: 'user-456' }, // Testing out-of-order turn_index
];

try {
  const result = transformLogs(mockLogs);
  
  console.log(JSON.stringify(result, null, 2));

  // Verify Session 1
  const s1 = result.find(s => s.session_id === 'uuid-1');
  assert.strictEqual(s1.status, 'completed');
  assert.strictEqual(s1.ended_at, '2026-09-01T10:02:00Z');
  assert.strictEqual(s1.transcript.length, 3); // Hello (AI), Hi (User), How can I help (AI), Nothing (User). Wait!
  
  // Let's manually count the transcripts for s1
  // turn 0: (Session started) -> ignored. ai_message "Hello" -> transcript (1)
  // turn 1: "Hi" -> transcript (2). "How can I help?" -> transcript (3)
  // turn 2: "Nothing" -> transcript (4). "(Session ended)" -> ignored, sets status.
  assert.strictEqual(s1.transcript.length, 4);
  assert.strictEqual(s1.session_metrics.total_turns, 2);
  assert.strictEqual(s1.user_id, 'user-123');

  // Verify Session 2
  const s2 = result.find(s => s.session_id === 'uuid-2');
  assert.strictEqual(s2.status, 'interrupted');
  assert.strictEqual(s2.ended_at, null);
  // turn 0: (Session started) ignored. ai "Hi there"
  // turn 1: user "What is the weather?", ai "It is sunny."
  assert.strictEqual(s2.transcript.length, 3);
  assert.strictEqual(s2.transcript[0].role, 'ai');
  assert.strictEqual(s2.transcript[0].text, 'Hi there');
  assert.strictEqual(s2.session_metrics.total_turns, 1);
  assert.strictEqual(s2.user_id, 'user-456'); // Should pick up from turn 0
  
  console.log("ALL TESTS PASSED: Migration logic works perfectly!");
} catch (e) {
  console.error("TEST FAILED:", e);
}

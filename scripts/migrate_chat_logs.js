const { createClient } = require('@supabase/supabase-js');

// ===========================================================
// Script: migrate_chat_logs.js
// Purpose: Migrate legacy chat logs from `chat_logs` into
//          structured JSONB sessions in `voice_chat_sessions`.
//
// Usage:
//   $env:SUPABASE_URL="https://houpzsxmwemoztpuigmo.supabase.co"
//   $env:SUPABASE_SERVICE_ROLE_KEY="<service_role_key>"
//   node scripts/migrate_chat_logs.js
// ===========================================================

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://houpzsxmwemoztpuigmo.supabase.co';
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_KEY) {
  console.error('[Error] SUPABASE_SERVICE_ROLE_KEY environment variable is required.');
  console.error('Please run: $env:SUPABASE_SERVICE_ROLE_KEY="<your_service_role_key>"');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

/**
 * Detects language by checking for Tamil Unicode codepoints (U+0B80–U+0BFF).
 * Returns 'ta' if any Tamil character is found, otherwise 'en'.
 */
function detectLanguage(text) {
  if (!text) return 'en';
  for (const char of text) {
    const code = char.codePointAt(0);
    if (code >= 0x0b80 && code <= 0x0bff) return 'ta';
  }
  return 'en';
}

async function migrate() {
  console.log(`Connecting to Supabase at: ${SUPABASE_URL}`);
  console.log('Fetching legacy chat logs from `public.chat_logs`...');
  
  let allLogs = [];
  let from = 0;
  const pageSize = 1000;
  let hasMore = true;
  
  // 1. Fetch all rows ordered chronologically
  while (hasMore) {
    const { data, error } = await supabase
      .from('chat_logs')
      .select('*')
      .order('conversation_uid', { ascending: true })
      .order('turn_index', { ascending: true })
      .range(from, from + pageSize - 1);
      
    if (error) {
      console.error('❌ Failed to fetch logs from `chat_logs`:', error);
      process.exit(1);
    }
    
    if (data && data.length > 0) {
      allLogs = allLogs.concat(data);
      from += pageSize;
    }
    if (!data || data.length < pageSize) {
      hasMore = false;
    }
  }

  if (allLogs.length === 0) {
    console.log('ℹ️ No chat logs found to migrate.');
    return;
  }

  console.log(`✅ Fetched ${allLogs.length} legacy rows. Grouping by conversation_uid...`);

  // 2. Group rows by conversation_uid
  const groups = {};
  for (const row of allLogs) {
    if (!groups[row.conversation_uid]) {
      groups[row.conversation_uid] = [];
    }
    groups[row.conversation_uid].push(row);
  }

  const distinctSessionIds = Object.keys(groups);
  console.log(`Found ${distinctSessionIds.length} unique sessions to transform.`);

  const newSessions = [];

  // 3. Transform grouped flat rows into voice_chat_sessions schema
  for (const [conversation_uid, rows] of Object.entries(groups)) {
    // Sort rows within the group chronologically based on created_at
    rows.sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
    
    let status = 'interrupted';
    let endedAt = null;
    let maxTurnIndex = 0;
    let transcript = [];
    let userId = null;

    for (const row of rows) {
      // Pick up authenticated user_id if present in any row
      if (row.user_id && !userId) {
        userId = row.user_id; 
      }
      
      if (row.turn_index > maxTurnIndex) {
        maxTurnIndex = row.turn_index;
      }

      // Check User message
      if (
        row.user_message && 
        row.user_message.trim() !== '' && 
        row.user_message !== 'null' && 
        row.user_message !== '(Session started)'
      ) {
        transcript.push({
          turn: row.turn_index,
          role: 'user',
          text: row.user_message.trim(),
          timestamp: row.created_at,
          detected_language: detectLanguage(row.user_message),
        });
      }

      // Check AI message
      if (
        row.ai_message && 
        row.ai_message.trim() !== '' && 
        row.ai_message !== 'null'
      ) {
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
    
    // Sort transcript explicitly by timestamp to guarantee absolute order 
    // even if rows had identical turn_index or if they were out of order.
    transcript.sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());

    // Clean up sequential turn indices so it's 1, 2, 3 instead of jumping around
    let currentTurn = 1;
    let lastRole = null;
    for (const msg of transcript) {
      if (msg.role === 'user' && lastRole !== 'user') {
        currentTurn++;
      }
      msg.turn = currentTurn === 1 && msg.role === 'ai' ? 1 : currentTurn;
      lastRole = msg.role;
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

  console.log(`Transformed into ${newSessions.length} sessions. Starting batch upsert into \`voice_chat_sessions\`...`);

  // 4. Batch upsert into voice_chat_sessions
  const insertChunkSize = 100;
  const totalBatches = Math.ceil(newSessions.length / insertChunkSize);
  let successfulBatches = 0;
  let failedBatches = 0;
  let totalMigratedCount = 0;
  const errors = [];

  for (let i = 0; i < newSessions.length; i += insertChunkSize) {
    const batchNumber = Math.floor(i / insertChunkSize) + 1;
    const chunk = newSessions.slice(i, i + insertChunkSize);
    
    console.log(`Upserting batch ${batchNumber}/${totalBatches} (${chunk.length} sessions)...`);

    const { error } = await supabase
      .from('voice_chat_sessions')
      .upsert(chunk, { onConflict: 'session_id' }); 
      
    if (error) {
      failedBatches++;
      console.error(`❌ Batch ${batchNumber} FAILED:`, error.message || error);
      errors.push({ batch: batchNumber, error });
    } else {
      successfulBatches++;
      totalMigratedCount += chunk.length;
      console.log(`✅ Batch ${batchNumber} succeeded (${chunk.length} sessions).`);
    }
  }

  // 5. Final validation & summary report
  console.log('\n================ MIGRATION REPORT ================');
  console.log(`Total legacy rows fetched:     ${allLogs.length}`);
  console.log(`Total sessions transformed:    ${newSessions.length}`);
  console.log(`Total batches attempted:       ${totalBatches}`);
  console.log(`Successful batches:            ${successfulBatches}`);
  console.log(`Failed batches:                ${failedBatches}`);
  console.log(`Total sessions migrated:       ${totalMigratedCount}/${newSessions.length}`);
  console.log('==================================================');

  if (failedBatches > 0) {
    console.error(`\n❌ Migration INCOMPLETE: ${failedBatches} batch(es) encountered errors.`);
    for (const e of errors) {
      console.error(`  - Batch ${e.batch}:`, e.error.message || e.error);
    }
    process.exit(1);
  }

  console.log('\n🎉 Migration completed successfully with zero errors!');
}

migrate().catch(err => {
  console.error('Unhandled migration failure:', err);
  process.exit(1);
});

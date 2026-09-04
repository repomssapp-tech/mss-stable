const { createClient } = require('@supabase/supabase-js');

// Instructions:
// 1. Run `npm init -y` and `npm install @supabase/supabase-js` if not already installed.
// 2. Set your Supabase URL and Service Role Key below, or via environment variables.
// 3. Run the script: `node migrate_chat_logs.js`

const SUPABASE_URL = process.env.SUPABASE_URL || 'YOUR_SUPABASE_URL';
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || 'YOUR_SUPABASE_SERVICE_ROLE_KEY';

if (SUPABASE_URL === 'YOUR_SUPABASE_URL' || SUPABASE_KEY === 'YOUR_SUPABASE_SERVICE_ROLE_KEY') {
  console.error("Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables or replace them in the script.");
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

async function migrate() {
  console.log('Fetching old chat logs from `chat_logs`...');
  
  let allLogs = [];
  let from = 0;
  const pageSize = 1000;
  let hasMore = true;
  
  // 1. Fetch all rows
  while (hasMore) {
    const { data, error } = await supabase
      .from('chat_logs')
      .select('*')
      .order('conversation_uid', { ascending: true })
      .order('turn_index', { ascending: true })
      .range(from, from + pageSize - 1);
      
    if (error) {
      console.error('Error fetching logs:', error);
      return;
    }
    
    if (data.length > 0) {
      allLogs = allLogs.concat(data);
      from += pageSize;
    }
    if (data.length < pageSize) {
      hasMore = false;
    }
  }

  console.log(`Fetched ${allLogs.length} rows. Grouping by conversation_uid...`);

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
      // Pick up a valid user_id if any row has it
      if (row.user_id && !userId) {
        userId = row.user_id; 
      }
      
      // Track maximum turn_index
      if (row.turn_index > maxTurnIndex) {
        maxTurnIndex = row.turn_index;
      }

      // Check User message
      if (row.user_message && row.user_message.trim() !== '' && row.user_message !== '(Session started)') {
        transcript.push({
          turn: row.turn_index,
          role: 'user',
          text: row.user_message,
          timestamp: row.created_at,
          detected_language: 'ta'
        });
      }

      // Check AI message
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
    
    // The session's start time is the created_at of its earliest row
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

  console.log(`Transformed into ${newSessions.length} new sessions. Starting batch insert into \`voice_chat_sessions\`...`);

  // 4. Batch insert into the new table
  const insertChunkSize = 500;
  for (let i = 0; i < newSessions.length; i += insertChunkSize) {
    const chunk = newSessions.slice(i, i + insertChunkSize);
    
    // Using upsert based on session_id (which is the primary key)
    // This allows re-running the script safely without duplicating records
    const { error } = await supabase
      .from('voice_chat_sessions')
      .upsert(chunk, { onConflict: 'session_id' }); 
      
    if (error) {
      console.error(`Error inserting batch ${i / insertChunkSize + 1}:`, error);
    } else {
      console.log(`Migrated batch ${i / insertChunkSize + 1} (${chunk.length} sessions)...`);
    }
  }

  console.log('Migration complete!');
}

migrate();

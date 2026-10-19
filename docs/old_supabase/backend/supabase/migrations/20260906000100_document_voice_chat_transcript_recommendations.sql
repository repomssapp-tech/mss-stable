-- ===========================================================
-- Migration: document_voice_chat_transcript_recommendations
-- Project  : MSS - MSME Schemes Search
-- Purpose  : Document the new contract for the public.voice_chat_sessions
--            transcript JSONB array where 'ai' role turns now include a
--            'recommendations' property.
-- ===========================================================

begin;

comment on table public.voice_chat_sessions is
    'Stores completed and interrupted voice assistant sessions with full transcript and metrics.
    transcript contract:
    - User turns: { turn, role: ''user'', text, timestamp, detected_language }
    - AI turns: { turn, role: ''ai'', text, timestamp, token_usage_ai, interrupted_by_user, recommendations: false | string[] }';

commit;

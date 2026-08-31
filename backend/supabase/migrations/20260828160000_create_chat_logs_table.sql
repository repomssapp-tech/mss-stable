-- Migration: Create dedicated chat logs table for voice and text AI interactions
-- Target: https://houpzsxmwemoztpuigmo.supabase.co

CREATE TABLE IF NOT EXISTS public.chat_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    conversation_uid TEXT NOT NULL,
    turn_index INT NOT NULL DEFAULT 1,
    mode TEXT NOT NULL CHECK (mode IN ('voice', 'text')),
    user_message TEXT NOT NULL,
    ai_message TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Indexes for efficient querying by conversation and time
CREATE INDEX IF NOT EXISTS idx_chat_logs_conversation_uid ON public.chat_logs (conversation_uid);
CREATE INDEX IF NOT EXISTS idx_chat_logs_created_at ON public.chat_logs (created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.chat_logs ENABLE ROW LEVEL SECURITY;

-- Allow insert from authenticated, anon, and service roles
CREATE POLICY "Allow log insertion" ON public.chat_logs
    FOR INSERT
    TO anon, authenticated, service_role
    WITH CHECK (true);

-- Allow read access for authenticated and service roles
CREATE POLICY "Allow read chat logs" ON public.chat_logs
    FOR SELECT
    TO anon, authenticated, service_role
    USING (true);

-- Grant permissions to public API roles
GRANT SELECT, INSERT ON TABLE public.chat_logs TO anon, authenticated, service_role;

-- Migration: Create scheduled_messages table
-- Replaces APScheduler + SQLite with Supabase-native persistence.
-- Scheduled messages survive server restarts/deploys and can be
-- queried directly by the Flutter app.

CREATE TABLE IF NOT EXISTS scheduled_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID REFERENCES auth.users(id) NOT NULL,
  recipient_names TEXT[] NOT NULL,
  message TEXT NOT NULL,
  send_at TIMESTAMPTZ NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'cancelled', 'failed')),
  created_at TIMESTAMPTZ DEFAULT now(),
  sent_at TIMESTAMPTZ,
  error TEXT
);

-- Index for the cron executor to efficiently find due messages
CREATE INDEX IF NOT EXISTS idx_scheduled_pending
  ON scheduled_messages (send_at)
  WHERE status = 'pending';

-- RLS: users can only see/manage their own scheduled messages
ALTER TABLE scheduled_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own scheduled messages"
  ON scheduled_messages FOR ALL
  USING (auth.uid() = sender_id);

-- Service role (used by the agent server and Edge Function) bypasses RLS,
-- so no additional policy is needed for the executor.

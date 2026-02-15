-- Migration: Create a Postgres function that processes due scheduled messages.
-- This runs directly inside Postgres via pg_cron — no Edge Function needed.
-- It resolves recipient names, inserts into the messages table, and updates status.

CREATE OR REPLACE FUNCTION process_scheduled_messages()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER  -- runs with owner privileges, bypasses RLS
AS $$
DECLARE
  rec RECORD;
  recipient_name TEXT;
  matched_user_id UUID;
  matched_username TEXT;
  all_sent BOOLEAN;
  errors TEXT[];
BEGIN
  -- Loop over all pending messages that are due
  FOR rec IN
    SELECT *
    FROM scheduled_messages
    WHERE status = 'pending'
      AND send_at <= now()
    FOR UPDATE SKIP LOCKED  -- prevent concurrent cron runs from double-processing
  LOOP
    all_sent := TRUE;
    errors := ARRAY[]::TEXT[];

    -- Process each recipient name
    FOREACH recipient_name IN ARRAY rec.recipient_names
    LOOP
      matched_user_id := NULL;
      matched_username := NULL;

      -- Try exact match first (case-insensitive)
      SELECT id, username INTO matched_user_id, matched_username
      FROM users
      WHERE lower(username) = lower(trim(recipient_name))
      LIMIT 1;

      -- Fall back to partial match if no exact match
      IF matched_user_id IS NULL THEN
        SELECT id, username INTO matched_user_id, matched_username
        FROM users
        WHERE lower(username) LIKE '%' || lower(trim(recipient_name)) || '%'
        LIMIT 1;
      END IF;

      -- If still no match, record error and continue
      IF matched_user_id IS NULL THEN
        all_sent := FALSE;
        errors := array_append(errors, 'Recipient not found: ' || recipient_name);
        CONTINUE;
      END IF;

      -- Insert the message
      BEGIN
        INSERT INTO messages (sender_id, receiver_id, content, is_read, message_type)
        VALUES (rec.sender_id, matched_user_id, rec.message, FALSE, 'text');
      EXCEPTION WHEN OTHERS THEN
        all_sent := FALSE;
        errors := array_append(errors, 'Failed to send to ' || matched_username || ': ' || SQLERRM);
      END;
    END LOOP;

    -- Update the scheduled message status
    UPDATE scheduled_messages
    SET
      status  = CASE WHEN all_sent THEN 'sent' ELSE 'failed' END,
      sent_at = now(),
      error   = CASE WHEN array_length(errors, 1) > 0
                     THEN array_to_string(errors, '; ')
                     ELSE NULL END
    WHERE id = rec.id;
  END LOOP;
END;
$$;

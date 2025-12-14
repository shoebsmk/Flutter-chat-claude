-- 1. Create the users table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
  username TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Add is_read column to messages table for unread message tracking
ALTER TABLE messages 
ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT FALSE NOT NULL;

-- 3. Create index for better query performance on unread messages
CREATE INDEX IF NOT EXISTS idx_messages_receiver_unread 
ON messages(receiver_id, is_read) 
WHERE is_read = FALSE;

-- 4. RPC function to mark messages as read (bypasses RLS)
-- This allows the receiver to mark messages sent TO them as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(sender_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  updated_count INTEGER;
BEGIN
  UPDATE messages
  SET is_read = TRUE
  WHERE sender_id = sender_user_id
    AND receiver_id = auth.uid()
    AND is_read = FALSE;
  
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  RETURN updated_count;
END;
$$;

-- 5. Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION mark_messages_as_read(UUID) TO authenticated;

-- 6. Add last_seen column to users table for online/offline status
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now());

-- 7. Create index for last_seen queries
CREATE INDEX IF NOT EXISTS idx_users_last_seen 
ON public.users(last_seen);

-- 8. Create typing_indicators table for real-time typing status
CREATE TABLE IF NOT EXISTS public.typing_indicators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  conversation_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  is_typing BOOLEAN DEFAULT FALSE NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, conversation_user_id)
);

-- 9. Create index for typing indicators queries
CREATE INDEX IF NOT EXISTS idx_typing_indicators_conversation 
ON public.typing_indicators(conversation_user_id, is_typing) 
WHERE is_typing = TRUE;

-- 10. Function to update user's last_seen timestamp
CREATE OR REPLACE FUNCTION update_last_seen()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE users
  SET last_seen = timezone('utc'::text, now())
  WHERE id = auth.uid();
END;
$$;

-- 11. Grant execute permission for update_last_seen
GRANT EXECUTE ON FUNCTION update_last_seen() TO authenticated;

-- 12. Add deleted_at column to messages table for message deletion
ALTER TABLE messages 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- 13. Create index for efficient filtering of non-deleted messages
CREATE INDEX IF NOT EXISTS idx_messages_deleted_at 
ON messages(deleted_at) 
WHERE deleted_at IS NULL;

-- 14. RPC function to delete a message (bypasses RLS)
-- This allows the sender to delete their own messages
CREATE OR REPLACE FUNCTION delete_message(message_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE messages
  SET deleted_at = timezone('utc'::text, now())
  WHERE id = message_id
    AND sender_id = auth.uid()
    AND deleted_at IS NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Message not found or you do not have permission to delete it';
  END IF;
END;
$$;

-- 15. Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_message(UUID) TO authenticated;

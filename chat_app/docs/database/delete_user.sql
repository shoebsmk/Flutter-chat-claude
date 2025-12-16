-- ============================================================================
-- SAFE USER DELETION SCRIPT FOR SUPABASE
-- ============================================================================
-- This script safely removes a user from the database without breaking
-- functionality. It handles all related data including messages, typing
-- indicators, and storage files.
--
-- IMPORTANT: Replace 'USER_ID_HERE' with the actual UUID of the user to delete
-- ============================================================================

-- Step 1: Set the user ID to delete (REPLACE THIS WITH ACTUAL USER ID)
DO $$
DECLARE
  user_to_delete UUID := 'USER_ID_HERE'; -- ⚠️ REPLACE THIS!
  deleted_messages_count INTEGER;
  deleted_typing_indicators_count INTEGER;
BEGIN
  -- Validate that the user exists
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = user_to_delete) THEN
    RAISE EXCEPTION 'User with ID % does not exist', user_to_delete;
  END IF;

  -- Step 2: Delete messages where user is sender or receiver
  -- Option A: Hard delete (completely remove messages)
  DELETE FROM public.messages
  WHERE sender_id = user_to_delete OR receiver_id = user_to_delete;
  
  GET DIAGNOSTICS deleted_messages_count = ROW_COUNT;
  RAISE NOTICE 'Deleted % messages', deleted_messages_count;

  -- Step 3: Delete typing indicators (will also cascade automatically, but explicit is safer)
  DELETE FROM public.typing_indicators
  WHERE user_id = user_to_delete OR conversation_user_id = user_to_delete;
  
  GET DIAGNOSTICS deleted_typing_indicators_count = ROW_COUNT;
  RAISE NOTICE 'Deleted % typing indicators', deleted_typing_indicators_count;

  -- Step 4: Delete storage files
  -- Delete profile picture
  DELETE FROM storage.objects
  WHERE bucket_id = 'profile-pictures'
    AND (storage.foldername(name))[1] = user_to_delete::text;

  -- Delete message attachments (files uploaded by this user)
  -- Note: This deletes files where the user is the sender
  -- You may want to keep attachments for other users, so this is optional
  DELETE FROM storage.objects
  WHERE bucket_id = 'message-attachments'
    AND (storage.foldername(name))[1] = user_to_delete::text;

  RAISE NOTICE 'Deleted storage files for user %', user_to_delete;

  -- Step 5: Delete from public.users FIRST (before auth.users)
  -- This must happen before deleting from auth.users to avoid FK constraint violation
  DELETE FROM public.users WHERE id = user_to_delete;

  -- Step 6: Finally delete from auth.users
  -- This removes the user from authentication
  DELETE FROM auth.users WHERE id = user_to_delete;

  RAISE NOTICE 'Successfully deleted user % and all related data', user_to_delete;

END $$;

-- ============================================================================
-- ALTERNATIVE: SOFT DELETE APPROACH (if you want to keep messages)
-- ============================================================================
-- If you prefer to keep messages but mark them as deleted, use this instead:
/*
DO $$
DECLARE
  user_to_delete UUID := 'USER_ID_HERE'; -- ⚠️ REPLACE THIS!
BEGIN
  -- Mark messages as deleted instead of hard deleting
  UPDATE public.messages
  SET deleted_at = timezone('utc'::text, now())
  WHERE (sender_id = user_to_delete OR receiver_id = user_to_delete)
    AND deleted_at IS NULL;

  -- Delete typing indicators
  DELETE FROM public.typing_indicators
  WHERE user_id = user_to_delete OR conversation_user_id = user_to_delete;

  -- Delete storage files
  DELETE FROM storage.objects
  WHERE bucket_id = 'profile-pictures'
    AND (storage.foldername(name))[1] = user_to_delete::text;

  -- Delete from auth.users (cascades to public.users)
  DELETE FROM auth.users WHERE id = user_to_delete;
END $$;
*/

-- ============================================================================
-- VERIFICATION QUERIES (Run these BEFORE deletion to see what will be deleted)
-- ============================================================================

-- Check user exists and see their details
-- SELECT id, email, created_at FROM auth.users WHERE id = 'USER_ID_HERE';

-- Count messages that will be deleted
-- SELECT 
--   COUNT(*) as total_messages,
--   COUNT(*) FILTER (WHERE sender_id = 'USER_ID_HERE') as sent_messages,
--   COUNT(*) FILTER (WHERE receiver_id = 'USER_ID_HERE') as received_messages
-- FROM public.messages
-- WHERE sender_id = 'USER_ID_HERE' OR receiver_id = 'USER_ID_HERE';

-- Count typing indicators that will be deleted
-- SELECT COUNT(*) as typing_indicators_count
-- FROM public.typing_indicators
-- WHERE user_id = 'USER_ID_HERE' OR conversation_user_id = 'USER_ID_HERE';

-- List storage files that will be deleted
-- SELECT name, bucket_id, created_at
-- FROM storage.objects
-- WHERE (bucket_id = 'profile-pictures' AND (storage.foldername(name))[1] = 'USER_ID_HERE')
--    OR (bucket_id = 'message-attachments' AND (storage.foldername(name))[1] = 'USER_ID_HERE');

-- ============================================================================
-- NOTES:
-- ============================================================================
-- 1. This script uses a DO block for transaction safety
-- 2. Typing indicators have ON DELETE CASCADE, so they'll be deleted automatically
--    when the user is deleted, but we delete them explicitly for clarity
-- 3. Messages do NOT have ON DELETE CASCADE, so they must be deleted explicitly
-- 4. Storage files are deleted explicitly to free up storage space
-- 5. Deleting from auth.users will automatically cascade to public.users
-- 6. All operations are logged with RAISE NOTICE for transparency
-- ============================================================================


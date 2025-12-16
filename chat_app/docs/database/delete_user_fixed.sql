-- ============================================================================
-- FIXED USER DELETION - Handles Foreign Key Constraint Issue
-- ============================================================================
-- This version deletes from public.users first, then auth.users
-- to avoid foreign key constraint violations
-- ============================================================================

DO $$
DECLARE
  user_to_delete UUID := 'YOUR_USER_ID_HERE'; -- ⚠️ CHANGE THIS!
  user_exists BOOLEAN;
BEGIN
  -- Validate user exists
  SELECT EXISTS(SELECT 1 FROM auth.users WHERE id = user_to_delete) INTO user_exists;
  IF NOT user_exists THEN
    RAISE EXCEPTION 'User with ID % does not exist', user_to_delete;
  END IF;

  -- Step 1: Delete messages (where user is sender or receiver)
  DELETE FROM public.messages
  WHERE sender_id = user_to_delete OR receiver_id = user_to_delete;
  RAISE NOTICE 'Deleted messages for user %', user_to_delete;

  -- Step 2: Delete typing indicators
  DELETE FROM public.typing_indicators
  WHERE user_id = user_to_delete OR conversation_user_id = user_to_delete;
  RAISE NOTICE 'Deleted typing indicators for user %', user_to_delete;

  -- Step 3: Delete profile picture from storage
  DELETE FROM storage.objects
  WHERE bucket_id = 'profile-pictures'
    AND (storage.foldername(name))[1] = user_to_delete::text;
  RAISE NOTICE 'Deleted profile picture for user %', user_to_delete;

  -- Step 4: Delete message attachments from storage
  DELETE FROM storage.objects
  WHERE bucket_id = 'message-attachments'
    AND (storage.foldername(name))[1] = user_to_delete::text;
  RAISE NOTICE 'Deleted message attachments for user %', user_to_delete;

  -- Step 5: CRITICAL - Delete from public.users FIRST
  -- This must be done before deleting from auth.users
  -- The foreign key constraint goes FROM public.users TO auth.users,
  -- so we can safely delete from public.users while auth.users still exists
  DELETE FROM public.users WHERE id = user_to_delete;
  RAISE NOTICE 'Deleted from public.users for user %', user_to_delete;

  -- Step 6: Now delete from auth.users (parent table)
  -- Since public.users is already deleted, this should work
  DELETE FROM auth.users WHERE id = user_to_delete;
  RAISE NOTICE 'Deleted from auth.users for user %', user_to_delete;

  RAISE NOTICE 'User % successfully deleted with all related data', user_to_delete;

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error deleting user %: % (SQLSTATE: %)', 
      user_to_delete, SQLERRM, SQLSTATE;
END $$;

-- ============================================================================
-- DIAGNOSTIC QUERIES (Run these first to check for issues)
-- ============================================================================

-- Check if user exists
-- SELECT id, email, created_at FROM auth.users WHERE id = 'YOUR_USER_ID_HERE';

-- Check if user exists in public.users
-- SELECT id, username FROM public.users WHERE id = 'YOUR_USER_ID_HERE';

-- Check for any remaining references (should return 0 rows after deletion)
-- SELECT 'messages' as table_name, COUNT(*) as count 
-- FROM public.messages 
-- WHERE sender_id = 'YOUR_USER_ID_HERE' OR receiver_id = 'YOUR_USER_ID_HERE'
-- UNION ALL
-- SELECT 'typing_indicators', COUNT(*) 
-- FROM public.typing_indicators 
-- WHERE user_id = 'YOUR_USER_ID_HERE' OR conversation_user_id = 'YOUR_USER_ID_HERE'
-- UNION ALL
-- SELECT 'public.users', COUNT(*) 
-- FROM public.users 
-- WHERE id = 'YOUR_USER_ID_HERE';


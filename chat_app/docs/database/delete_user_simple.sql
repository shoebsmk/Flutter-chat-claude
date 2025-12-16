-- ============================================================================
-- SIMPLE USER DELETION - Quick Copy & Paste Version (FIXED)
-- ============================================================================
-- Instructions:
-- 1. First, find the user by username using the query below
-- 2. Replace 'YOUR_USER_ID_HERE' below with the actual user UUID
-- 3. Run the deletion script in Supabase SQL Editor
-- 4. This will safely delete the user and all related data
--
-- IMPORTANT: Deletes from public.users FIRST, then auth.users to avoid
-- foreign key constraint violations.
-- ============================================================================

-- ============================================================================
-- STEP 1: FIND USER BY USERNAME (Run this first to get the user ID)
-- ============================================================================
-- Replace 'username_here' with the actual username
SELECT 
  u.id,
  u.username,
  au.email,
  u.created_at,
  u.last_seen
FROM public.users u
JOIN auth.users au ON u.id = au.id
WHERE u.username = 'username_here';  -- ⚠️ CHANGE THIS!

-- Alternative: Find by email
-- SELECT 
--   u.id,
--   u.username,
--   au.email,
--   u.created_at
-- FROM public.users u
-- JOIN auth.users au ON u.id = au.id
-- WHERE au.email = 'user@example.com';  -- ⚠️ CHANGE THIS!

-- ============================================================================
-- STEP 2: DELETE USER (Use the ID from Step 1)
-- ============================================================================

DO $$
DECLARE
  user_to_delete UUID := 'YOUR_USER_ID_HERE'; -- ⚠️ CHANGE THIS!
BEGIN
  -- Step 1: Delete messages (where user is sender or receiver)
  DELETE FROM public.messages
  WHERE sender_id = user_to_delete OR receiver_id = user_to_delete;

  -- Step 2: Delete typing indicators
  DELETE FROM public.typing_indicators
  WHERE user_id = user_to_delete OR conversation_user_id = user_to_delete;

  -- Step 3: Delete profile picture from storage
  DELETE FROM storage.objects
  WHERE bucket_id = 'profile-pictures'
    AND (storage.foldername(name))[1] = user_to_delete::text;

  -- Step 4: Delete message attachments from storage
  DELETE FROM storage.objects
  WHERE bucket_id = 'message-attachments'
    AND (storage.foldername(name))[1] = user_to_delete::text;

  -- Step 5: CRITICAL - Delete from public.users FIRST
  -- The foreign key constraint goes FROM public.users TO auth.users,
  -- so we must delete the child table (public.users) before the parent (auth.users)
  DELETE FROM public.users WHERE id = user_to_delete;

  -- Step 6: Finally delete from auth.users (parent table)
  -- Now that public.users is deleted, this should work without constraint violations
  DELETE FROM auth.users WHERE id = user_to_delete;

  RAISE NOTICE 'User % successfully deleted', user_to_delete;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error deleting user: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END $$;


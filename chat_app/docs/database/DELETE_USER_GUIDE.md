# User Deletion Guide

This guide explains how to safely delete a user from your Supabase database without breaking any functionality.

## Quick Start

1. **Get the User ID**: Find the UUID of the user you want to delete
   ```sql
   SELECT id, email, created_at FROM auth.users WHERE email = 'user@example.com';
   ```

2. **Run the deletion script**: Use `delete_user_simple.sql` and replace `YOUR_USER_ID_HERE` with the actual UUID

3. **Verify deletion**: Confirm the user is gone
   ```sql
   SELECT * FROM auth.users WHERE id = 'USER_ID_HERE';
   -- Should return no rows
   ```

## What Gets Deleted

When you delete a user, the following data is removed:

### ✅ Automatically Deleted (via CASCADE)
- **`public.users`** - User profile (cascades from `auth.users`)
- **`typing_indicators`** - Typing status records (has `ON DELETE CASCADE`)

### ✅ Explicitly Deleted (by script)
- **`messages`** - All messages where user is sender or receiver
- **Storage files**:
  - Profile pictures from `profile-pictures` bucket
  - Message attachments from `message-attachments` bucket

## Two Approaches

### 1. Hard Delete (Default)
Completely removes the user and all their messages. Use `delete_user_simple.sql`.

**When to use:**
- GDPR compliance (right to be forgotten)
- Spam/abusive accounts
- Test accounts
- Complete data removal

### 2. Soft Delete (Alternative)
Keeps messages but marks them as deleted. Modify the script to use:
```sql
-- Instead of DELETE, use UPDATE:
UPDATE public.messages
SET deleted_at = timezone('utc'::text, now())
WHERE (sender_id = user_to_delete OR receiver_id = user_to_delete)
  AND deleted_at IS NULL;
```

**When to use:**
- Preserve conversation history
- Legal/compliance requirements
- Analytics purposes

## Verification Before Deletion

Before deleting, you can check what will be affected:

```sql
-- Replace with actual user ID
SET user_id = 'USER_ID_HERE';

-- Count messages
SELECT 
  COUNT(*) as total_messages,
  COUNT(*) FILTER (WHERE sender_id = user_id) as sent,
  COUNT(*) FILTER (WHERE receiver_id = user_id) as received
FROM public.messages
WHERE sender_id = user_id OR receiver_id = user_id;

-- Count typing indicators
SELECT COUNT(*) 
FROM public.typing_indicators
WHERE user_id = user_id OR conversation_user_id = user_id;

-- List storage files
SELECT name, bucket_id 
FROM storage.objects
WHERE (bucket_id = 'profile-pictures' AND (storage.foldername(name))[1] = user_id::text)
   OR (bucket_id = 'message-attachments' AND (storage.foldername(name))[1] = user_id::text);
```

## Important Notes

⚠️ **Warning**: User deletion is **irreversible**. Make sure you have backups if needed.

✅ **Safe**: The script uses a transaction (`DO $$` block), so if any step fails, nothing is deleted.

✅ **Complete**: All related data is cleaned up, preventing orphaned records.

✅ **Storage**: Storage files are deleted to free up space and comply with data removal requests.

## Database Schema Context

Your database has these relationships:

```
auth.users (1) ──CASCADE──> (1) public.users
                                    │
                                    ├──> (many) messages (sender_id)
                                    ├──> (many) messages (receiver_id)
                                    ├──> (many) typing_indicators (user_id)
                                    └──> (many) typing_indicators (conversation_user_id)
```

- `public.users` → `auth.users`: **CASCADE DELETE** ✅
- `typing_indicators` → `users`: **CASCADE DELETE** ✅
- `messages` → `users`: **NO CASCADE** ⚠️ (must delete explicitly)

## Troubleshooting

### Error: "Foreign key constraint violation" (users_id_fkey)

**This error occurs when trying to delete from `auth.users` while `public.users` still references it.**

**Solution:** Use the fixed script (`delete_user_fixed.sql`) which deletes from `public.users` FIRST, then from `auth.users`. The deletion order is critical:

1. Delete messages
2. Delete typing indicators  
3. Delete storage files
4. **Delete from `public.users` FIRST** ⚠️
5. Delete from `auth.users` last

The foreign key constraint goes FROM `public.users` TO `auth.users`, so you can delete from `public.users` while `auth.users` still exists, but not the other way around.

### Error: "User does not exist"
- Verify the user ID is correct
- Check if user was already deleted

### Error: "Permission denied"
- Ensure you're running as a database admin
- Check RLS policies if needed
- You may need to use Supabase Dashboard SQL Editor with admin privileges

### Messages still visible after deletion
- Check if you used soft delete approach
- Verify the deletion script completed successfully
- Check if messages are filtered by `deleted_at IS NULL` in your app

## Files

- **`delete_user_simple.sql`** - Quick, ready-to-use script
- **`delete_user.sql`** - Detailed version with comments and alternatives

## Support

If you encounter issues:
1. Check Supabase logs
2. Verify user ID is correct
3. Ensure you have proper permissions
4. Review the detailed script for error handling


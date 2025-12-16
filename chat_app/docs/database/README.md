# Database Documentation

This directory contains SQL scripts and database management guides for the Supabase backend.

## 📋 Available Scripts

### User Management

#### [Delete User Guide](./DELETE_USER_GUIDE.md)
Complete guide for safely deleting users from the database:
- Step-by-step instructions
- Safety considerations
- Troubleshooting common errors
- Verification queries

#### [Delete User Scripts](./delete_user_simple.sql)
Ready-to-use SQL scripts for user deletion:
- **delete_user_simple.sql** - Quick copy-paste version with username lookup
- **delete_user.sql** - Detailed version with comments and alternatives
- **delete_user_fixed.sql** - Version with enhanced error handling

**Usage:**
1. Find user by username (query included in script)
2. Replace `YOUR_USER_ID_HERE` with the actual UUID
3. Run in Supabase SQL Editor

### Database Setup

#### [Supabase Setup](./supabase_setup.sql)
Initial database schema and configuration:
- Users table creation
- Messages table setup
- Typing indicators table
- Indexes and performance optimization
- RPC functions for message operations
- Storage bucket configuration

#### [Profile Migration](./supabase_profile_migration.sql)
Migration script for profile editing features:
- Avatar URL column
- Bio column
- Updated timestamp tracking
- Storage policies for profile pictures
- Constraints and validation

## 🔧 Usage

### Running Scripts

1. Open Supabase Dashboard
2. Navigate to SQL Editor
3. Copy and paste the script
4. Replace any placeholder values (like user IDs)
5. Execute the script

### Safety Notes

⚠️ **Always backup your database before running deletion scripts**

✅ Scripts use transactions for safety
✅ Validation checks are included
✅ Error handling prevents partial deletions

## 📚 Related Documentation

- [Architecture Documentation](../architecture/ARCHITECTURE.md) - Database schema details
- [Supabase Functions](../../supabase/functions/) - Edge function documentation

## 🔍 Quick Reference

```sql
-- Find user by username
SELECT id, username, email 
FROM public.users u
JOIN auth.users au ON u.id = au.id
WHERE u.username = 'username_here';
```


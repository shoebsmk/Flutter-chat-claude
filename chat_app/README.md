# Chat App (AI‑assisted)

Basic chat app scaffold built with Flutter and Supabase, created using AI coding tools. It includes email/password auth, a public `users` table synced from `auth.users`, and a starter UI for listing users and navigating to chat.

## Features

- Email/password authentication via Supabase Auth (`auth.users`)
- Client-side sync of profiles into `public.users` after signup/signin
- Streamed user list from Supabase (`public.users`)
- Simple navigation to a placeholder chat screen

## Prerequisites

- Flutter SDK installed (see `flutter --version`)
- A Supabase project and keys

## Supabase Setup

1. Create a new Supabase project at https://supabase.com
2. Copy your `Project URL` and `anon` key from Project Settings → API
3. Optional: Run the SQL in your Supabase SQL Editor to create a trigger for server-side sync and backfill (RLS is disabled by default in the script). The client already handles user creation without this.

   - Open `chat_app/supabase_setup.sql`
   - Copy the contents into Supabase → SQL → New query
   - Run the script, then verify `public.users` exists and is populated

The script also backfills existing `auth.users` into `public.users` so previously registered users appear.

### Optional: Enable RLS for `public.users`

If you prefer Row Level Security, enable it and add policies that allow global read while restricting writes to the owner. Example:

```
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_read_all"
ON public.users FOR SELECT
USING (true);

CREATE POLICY "users_update_own"
ON public.users FOR UPDATE
USING (auth.uid() = id);
```

Note: The trigger that inserts into `public.users` runs as a definer and will continue to work with RLS enabled.

## App Configuration

This app initializes Supabase in `lib/main.dart`:

- `chat_app/lib/main.dart:8` sets `Supabase.initialize(url, anonKey)`
- For production, prefer passing secrets via `--dart-define` instead of hardcoding

Example using `--dart-define`:

```
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Adapt `main.dart` to read `const String.fromEnvironment('SUPABASE_URL')` and `const String.fromEnvironment('SUPABASE_ANON_KEY')` if you choose this approach.

## Run Locally

- From `chat_app/`:
  - `flutter pub get`
  - `flutter run`

On first launch:

- Sign up with email/password and a username
- The trigger inserts a row into `public.users`
- The Chat List screen streams `public.users` and shows other users

## Code Pointers

- Supabase init and session routing: `chat_app/lib/main.dart:8` and `chat_app/lib/main.dart:20`
- Auth (sign up/sign in) and metadata: `chat_app/lib/screens/auth_screen.dart:21`
- User list stream and navigation: `chat_app/lib/screens/chat_list_screen.dart:19`

## Troubleshooting

- Users not appearing in `public.users`:
  - Ensure you ran `supabase_setup.sql`
  - Verify the trigger `on_auth_user_created` exists on `auth.users`
  - Check RLS policies allow `SELECT` on `public.users`

- UID shown in AppBar:
  - Update the title to `Text('Chats')` or fetch and display the current user’s `username`

## Notes

- A sample credential list exists at `chat_app/my_users.txt` (for testing flows)
- Do not commit secrets; use environment variables or `--dart-define` for keys

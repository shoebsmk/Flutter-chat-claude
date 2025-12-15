# Chat App (AI‑assisted)

A full-featured real-time chat application built with Flutter and Supabase. Features include real-time messaging with read receipts, typing indicators, presence tracking, profile editing, image and file attachments, contact profiles, and **Chat Assist** that lets you send messages using natural language commands like "Send Ahmed I'll be late" or "Message John Hello there".

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Setup](#setup)
  - [Supabase Setup](#supabase-setup)
  - [App Configuration](#app-configuration)
  - [Simulator/Emulator Setup](#simulatoremulator-setup)
- [Running the App](#running-the-app)
  - [Initial Setup](#initial-setup)
  - [Running on iOS Simulator](#running-on-ios-simulator)
  - [Running on Android Emulator](#running-on-android-emulator)
  - [First Launch](#first-launch)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Additional Resources](#additional-resources)

## Features

- Email/password authentication via Supabase Auth (`auth.users`)
- Client-side sync of profiles into `public.users` after signup/signin
- Streamed user list from Supabase (`public.users`)
- Real-time messaging with read receipts
- Typing indicators
- Online/offline status (presence tracking)
- Unread message tracking
- User search functionality
- Profile editing (username, bio, profile picture upload)
- **Image and file attachments** - Send images from gallery or camera with automatic compression and validation
- **Contact profiles** - View detailed contact information including avatar, bio, and online status
- **Enhanced settings** - About & Support section with app version, feedback links, and more
- **Chat Assist** - Send messages using natural language commands like "Send Ahmed I'll be late" or "Message John Hello there" (formerly AI Assistant)

## Prerequisites

Before you begin, ensure you have the following installed and configured:

- **Flutter SDK** (>=3.0.0 recommended)
  - Verify installation: `flutter --version`
  - Install: https://flutter.dev/docs/get-started/install
- **Supabase Account** and project
  - Sign up: https://supabase.com
  - Create a new project to get your API keys
- **For iOS development** (macOS only):
  - **Xcode** (latest version recommended)
  - Verify installation: `xcode-select --print-path`
  - Install: Mac App Store or [developer.apple.com](https://developer.apple.com/xcode/)
- **For Android development:**
  - **Android Studio** (latest version recommended)
  - Verify setup: `flutter doctor`
  - Install: [developer.android.com/studio](https://developer.android.com/studio)

## Quick Start

For experienced developers who want to get started quickly:

1. **Set up Supabase:**
   - Create a Supabase project and get your API keys
   - Run the SQL setup scripts (see [Supabase Setup](#supabase-setup))

2. **Configure the app:**
   - Update `lib/main.dart` with your Supabase URL and anon key
   - Or use `--dart-define` flags (see [App Configuration](#app-configuration))

3. **Install dependencies:**
   ```bash
   cd chat_app
   flutter pub get
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

For detailed setup instructions, continue reading below.

## Setup

### Supabase Setup

1. **Create a Supabase project:**
   - Go to https://supabase.com and create a new project
   - Wait for the project to finish initializing

2. **Get your API keys:**
   - Navigate to Project Settings → API
   - Copy your `Project URL` and `anon` key
   - You'll need these for app configuration

3. **Run the database setup script:**
   - Open `chat_app/supabase_setup.sql`
   - Copy the contents into Supabase → SQL Editor → New query
   - Run the script
   - Verify `public.users` table exists and is populated

   > **Note:** This script creates a trigger for server-side sync and backfills existing `auth.users` into `public.users`. The client already handles user creation without this, but the trigger ensures consistency.

4. **Profile Editing Setup:**
   - Run the profile migration script for profile editing features:
   - Open `chat_app/supabase_profile_migration.sql`
   - Copy the contents into Supabase → SQL Editor → New query
   - Run the script to add `avatar_url`, `bio`, and `updated_at` columns
   - This also creates the `profile-pictures` storage bucket with proper policies

5. **Image and File Attachment Setup:**
   - Ensure message attachments are supported by your database schema
   - The `messages` table should have columns: `message_type`, `file_url`, `file_name`, `file_size`
   - Create a `message-attachments` storage bucket in Supabase Storage with:
     - Public read access for viewing attachments
     - Authenticated write access for uploading
   - See your migration scripts or schema for exact column definitions

5. **AI Command Feature Setup (Optional):**
   
   The AI command feature supports multiple providers (OpenAI and Gemini) with automatic fallback.
   
   **Option 1: Using OpenAI (Default)**
   - Get an OpenAI API key from https://platform.openai.com/api-keys
   - Set the API key in Supabase:
     - Go to Project Settings → Edge Functions → Secrets
     - Add `ChatApp` with your OpenAI API key value
   
   **Option 2: Using Gemini**
   - Get a Gemini API key from https://aistudio.google.com/app/apikey
   - Set the API key in Supabase:
     - Go to Project Settings → Edge Functions → Secrets
     - Add `GEMINI_API_KEY` with your API key value
     - Add `AI_PROVIDER=gemini` to use Gemini as the primary provider
   
   **Option 3: Configure Both Providers (Recommended)**
   - Set up both providers for automatic fallback:
     - Add `ChatApp` with your OpenAI API key
     - Add `GEMINI_API_KEY` with your Gemini API key
     - Add `AI_PROVIDER=openai` (or `gemini`) for primary provider
     - Add `AI_FALLBACK_PROVIDER=gemini` (or `openai`) for fallback
   
   **Deploy the Edge Function:**
   - Using CLI: `supabase functions deploy extract-message-intent`
   - Or via Dashboard: Edge Functions → Deploy new function
   - See `DEPLOYMENT_GUIDE.md` and `supabase/functions/extract-message-intent/README.md` for details

#### Optional: Enable RLS for `public.users`

If you prefer Row Level Security, enable it and add policies that allow global read while restricting writes to the owner:

```sql
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_read_all"
ON public.users FOR SELECT
USING (true);

CREATE POLICY "users_update_own"
ON public.users FOR UPDATE
USING (auth.uid() = id);
```

> **Note:** The trigger that inserts into `public.users` runs as a definer and will continue to work with RLS enabled.

### App Configuration

This app initializes Supabase in `lib/main.dart`. You have two options for configuration:

#### Option 1: Direct Configuration (Development)

Update `lib/main.dart` directly with your Supabase credentials:

```dart
Supabase.initialize(
  url: 'https://YOUR_PROJECT.supabase.co',
  anonKey: 'YOUR_ANON_KEY',
);
```

#### Option 2: Environment Variables (Recommended for Production)

Use `--dart-define` flags to pass secrets securely:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

To use this approach, adapt `main.dart` to read from environment:

```dart
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseAnonKey,
);
```

> **Security Note:** Never commit secrets to version control. Use environment variables or `--dart-define` for production deployments.

### Simulator/Emulator Setup

#### iOS Simulator Setup (macOS only)

1. **Install Xcode:**
   - Download Xcode from the Mac App Store or [developer.apple.com](https://developer.apple.com/xcode/)
   - Open Xcode and accept the license agreement
   - Install additional components when prompted (Command Line Tools)

2. **Install iOS Simulator:**
   - Open Xcode → Preferences → Components (or Platforms & Simulators)
   - Download the iOS Simulator runtime for your target iOS version
   - Alternatively, install via Xcode → Settings → Platforms

3. **Create a Simulator:**
   - Open Xcode → Window → Devices and Simulators (or press `Cmd + Shift + 2`)
   - Click the "+" button in the bottom left
   - Choose:
     - **Device Type:** iPhone (e.g., iPhone 15 Pro, iPhone 14)
     - **OS Version:** Latest available or your target version
   - Click "Create"

4. **Verify Setup:**
   ```bash
   flutter doctor
   ```
   Ensure iOS toolchain shows no issues. If you see errors:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

5. **List Available Simulators:**
   ```bash
   flutter devices
   # or
   xcrun simctl list devices
   ```

#### Android Emulator Setup

1. **Install Android Studio:**
   - Download from [developer.android.com/studio](https://developer.android.com/studio)
   - Install Android Studio and launch it
   - Complete the setup wizard (SDK components will be installed)

2. **Install Android SDK:**
   - Open Android Studio → Preferences → Appearance & Behavior → System Settings → Android SDK
   - In the SDK Platforms tab, select:
     - Latest Android version (e.g., Android 14.0 "UpsideDownCake")
     - At least one older version for compatibility (e.g., Android 13.0 "Tiramisu")
   - In the SDK Tools tab, ensure these are checked:
     - Android SDK Build-Tools
     - Android Emulator
     - Android SDK Platform-Tools
     - Intel x86 Emulator Accelerator (HAXM installer) - for Intel Macs
     - Google Play services (if needed)
   - Click "Apply" and wait for installation

3. **Set Environment Variables (if not auto-configured):**
   ```bash
   # Add to ~/.zshrc or ~/.bash_profile
   export ANDROID_HOME=$HOME/Library/Android/sdk
   export PATH=$PATH:$ANDROID_HOME/emulator
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   export PATH=$PATH:$ANDROID_HOME/tools
   export PATH=$PATH:$ANDROID_HOME/tools/bin
   ```
   Then reload:
   ```bash
   source ~/.zshrc  # or source ~/.bash_profile
   ```

4. **Create an Android Virtual Device (AVD):**
   - Open Android Studio → Tools → Device Manager (or AVD Manager)
   - Click "Create Device"
   - Choose a device definition (e.g., Pixel 7, Pixel 6)
   - Select a system image:
     - Recommended: Latest release with Google Play (for Play Services)
     - Or: Latest release without Google Play (for vanilla Android)
   - Click "Download" if the system image isn't installed
   - Click "Next" → Configure AVD (optional: adjust RAM, resolution)
   - Click "Finish"

5. **Verify Setup:**
   ```bash
   flutter doctor
   ```
   Ensure Android toolchain shows no issues. If you see errors:
   ```bash
   flutter doctor --android-licenses  # Accept all licenses
   ```

6. **List Available Emulators:**
   ```bash
   flutter devices
   # or
   emulator -list-avds
   ```

#### Quick Start Commands

**Start iOS Simulator:**
```bash
open -a Simulator
# or launch a specific device
xcrun simctl boot "iPhone 15 Pro"
```

**Start Android Emulator:**
```bash
# List available AVDs
emulator -list-avds

# Start a specific emulator
emulator -avd <avd_name>
# Example: emulator -avd Pixel_7_API_34
```

## Running the App

### Initial Setup

1. **Install dependencies:**
   ```bash
   cd chat_app
   flutter pub get
   ```

2. **Verify your setup:**
   ```bash
   flutter doctor
   ```
   Fix any issues reported before proceeding.

### Running on iOS Simulator

**Prerequisites:** Complete [iOS Simulator Setup](#ios-simulator-setup-macos-only) above.

1. **Start the iOS Simulator:**
   ```bash
   open -a Simulator
   ```
   Or launch a specific device:
   ```bash
   xcrun simctl boot "iPhone 15 Pro"
   ```

2. **List available devices:**
   ```bash
   flutter devices
   ```
   You should see your iOS simulator listed with a device ID.

3. **Run the app:**
   ```bash
   flutter run
   ```
   Flutter will automatically detect and use the running simulator.

   Or specify a device explicitly:
   ```bash
   flutter run -d <device-id>
   ```
   
   Example:
   ```bash
   flutter run -d 2198D535-93C4-45D7-843B-3453AA3C5FF6
   ```

4. **Interactive commands while running:**
   - Press `r` for hot reload (quick code changes)
   - Press `R` for hot restart (full app restart)
   - Press `q` to quit the app
   - Press `h` for help

### Running on Android Emulator

**Prerequisites:** Complete [Android Emulator Setup](#android-emulator-setup) above.

1. **Start the Android Emulator:**
   ```bash
   # List available AVDs
   emulator -list-avds
   
   # Start a specific emulator
   emulator -avd <avd_name> &
   ```
   Example:
   ```bash
   emulator -avd Pixel_7_API_34 &
   ```
   Wait for the emulator to fully boot (you'll see the Android home screen).

2. **List available devices:**
   ```bash
   flutter devices
   ```
   You should see your Android emulator listed (may take a moment after boot).

3. **Run the app:**
   ```bash
   flutter run
   ```
   Flutter will automatically detect and use the running emulator.

   Or specify a device explicitly:
   ```bash
   flutter run -d <device-id>
   ```

4. **Interactive commands while running:**
   - Press `r` for hot reload (quick code changes)
   - Press `R` for hot restart (full app restart)
   - Press `q` to quit the app
   - Press `h` for help

### First Launch

On first launch:

- Sign up with email/password and a username
- The trigger inserts a row into `public.users`
- The Chat List screen streams `public.users` and shows other users

## Project Structure

Key files and their purposes:

- **Supabase initialization and session routing:**
  - `lib/main.dart:8` - Supabase initialization
  - `lib/main.dart:20` - Session routing logic

- **Authentication:**
  - `lib/screens/auth_screen.dart:21` - Sign up/sign in and metadata handling

- **User management:**
  - `lib/screens/chat_list_screen.dart:19` - User list stream and navigation
  - `lib/services/user_service.dart` - User data operations

- **Chat functionality:**
  - `lib/screens/chat_screen.dart` - Chat interface
  - `lib/services/chat_service.dart` - Message operations and real-time updates
  - `lib/models/message.dart` - Message data model

- **Profile editing:**
  - `lib/screens/profile_edit_screen.dart` - Profile editing UI
  - `lib/services/profile_service.dart` - Image upload, validation, and profile updates

- **Chat Assist (AI command messaging):**
  - `lib/screens/main_screen.dart` - Main container with bottom navigation (Chats & Chat Assist tabs)
  - `lib/screens/ai_assistant_screen.dart` - Chat Assist interface for natural language messaging with message history
  - `lib/services/ai_command_service.dart` - AI intent extraction and recipient resolution
  - `supabase/functions/extract-message-intent/` - Edge Function for AI intent extraction (supports OpenAI and Gemini with automatic fallback)

- **File and image attachments:**
  - `lib/services/file_upload_service.dart` - Image compression, resizing, and Supabase storage upload
  - `lib/widgets/message_bubble.dart` - Display image attachments with preview
  - `lib/widgets/message_input.dart` - Image picker (gallery and camera) integration

- **Contact profiles:**
  - `lib/screens/contact_profile_screen.dart` - Contact details view with avatar, bio, and online status
  - Navigate from chat screen header to view contact profile

- **Real-time features:**
  - `lib/services/presence_service.dart` - Online/offline status tracking
  - `lib/services/typing_service.dart` - Typing indicators

- **Configuration:**
  - `lib/config/supabase_config.dart` - Supabase configuration
  - `lib/theme/app_theme.dart` - App theming

## Troubleshooting

### Simulator/Emulator Issues

- **iOS Simulator not detected:**
  - Ensure Xcode is properly installed: `xcode-select --print-path`
  - Run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
  - Verify simulator is running: `xcrun simctl list devices available`
  - Try restarting the simulator: `killall Simulator && open -a Simulator`

- **Android Emulator not detected:**
  - Ensure emulator is fully booted (wait for Android home screen)
  - Check `ANDROID_HOME` is set: `echo $ANDROID_HOME`
  - Verify emulator is running: `adb devices`
  - If emulator won't start, check system requirements (RAM, virtualization enabled)
  - For Intel Macs, ensure HAXM is installed: Android Studio → SDK Manager → SDK Tools → Intel x86 Emulator Accelerator

- **"No devices found" error:**
  - Run `flutter doctor` to identify missing components
  - Ensure at least one simulator/emulator is running before `flutter run`
  - Try `flutter devices` to see what Flutter detects
  - Restart your IDE/terminal after installing new SDKs

- **Build errors on iOS:**
  - Run `cd ios && pod install && cd ..` to install CocoaPods dependencies
  - Clean build: `flutter clean && flutter pub get`
  - Ensure you have the latest Xcode Command Line Tools

- **Build errors on Android:**
  - Accept Android licenses: `flutter doctor --android-licenses`
  - Ensure `ANDROID_HOME` environment variable is set correctly
  - Clean build: `flutter clean && flutter pub get`
  - Check Gradle version compatibility in `android/build.gradle.kts`

### App-Specific Issues

- **Users not appearing in `public.users`:**
  - Ensure you ran `supabase_setup.sql`
  - Verify the trigger `on_auth_user_created` exists on `auth.users`
  - Check RLS policies allow `SELECT` on `public.users`

- **Profile editing not working:**
  - Ensure you ran `supabase_profile_migration.sql` to add profile columns
  - Verify the `profile-pictures` storage bucket exists
  - Check storage policies allow authenticated users to upload to their own folder
  - On web, ensure you're using a modern browser (Chrome, Firefox, Edge)

- **Image upload fails:**
  - Check file size (max 5MB before compression)
  - Verify image format (JPEG, PNG, WebP supported)
  - On mobile, ensure camera/storage permissions are granted
  - On web, no permissions needed (browser handles file access)

- **Image attachments not working:**
  - Verify the `message-attachments` storage bucket exists in Supabase Storage
  - Check storage policies allow authenticated users to upload and public users to read
  - Ensure file size is within limits (max 5MB before compression, compressed to max 2000x2000px)
  - On mobile, ensure camera/storage permissions are granted
  - On web, ensure you're using a modern browser with file API support
  - Verify `messages` table has attachment columns: `message_type`, `file_url`, `file_name`, `file_size`

- **Chat Assist (AI command feature) not working:**
  - Verify API key secrets are set in Supabase Edge Functions:
    - For OpenAI: `ChatApp` secret
    - For Gemini: `GEMINI_API_KEY` secret
    - For provider selection: `AI_PROVIDER` and `AI_FALLBACK_PROVIDER` (optional)
  - Ensure the `extract-message-intent` Edge Function is deployed
  - Check Edge Function logs in Supabase dashboard for errors
  - Verify your API keys are valid and have quota remaining
  - See `DEPLOYMENT_GUIDE.md` and `supabase/functions/extract-message-intent/README.md` for detailed setup instructions

- **UID shown in AppBar:**
  - Update the title to `Text('Chats')` or fetch and display the current user's `username`

## Additional Resources

- **Sample credentials:** `chat_app/my_users.txt` (for testing flows)
- **Architecture documentation:** See `ARCHITECTURE.md` for detailed system design
- **Chat Assist (AI command feature):** 
  - Implementation details: `docs/AI_COMMAND_MESSAGING_PLAN.md`
  - Implementation summary: `docs/AI_COMMAND_IMPLEMENTATION_SUMMARY.md`
  - Deployment guide: `DEPLOYMENT_GUIDE.md`
  - Edge Function README: `supabase/functions/extract-message-intent/README.md`
- **Testing:** See `test/TESTING.md` for testing instructions and coverage information
- **Feature suggestions:** See `docs/FEATURE_SUGGESTIONS.md` for potential enhancements
- **Implementation history:** See `docs/IMPLEMENTATION_HISTORY.md` for development progress
- **Security best practices:**
  - Do not commit secrets to version control
  - Use environment variables or `--dart-define` for API keys
  - Enable RLS in production for better security

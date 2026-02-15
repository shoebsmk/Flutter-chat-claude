# Firebase Deployment Plan for SmartChat Flutter App

## Context
The SmartChat app has new features from the `feature/agent-upgrade` branch (AI agent integration, retry logic, offline detection) that need to be deployed to Firebase Hosting. The deployment pipeline is fully configured and tested with automated build-on-deploy hooks. We're deploying the current branch state to update the live application at https://smart-chat-78868.web.app.

## Current State
- **Branch:** `feature/agent-upgrade` (up to date with remote)
- **Changes:** 24 files changed with new AI agent features, improved error handling, and async capabilities
- **Firebase Project:** `smart-chat-78868`
- **Live URL:** https://smart-chat-78868.web.app
- **Only pending change:** Firebase cache file (auto-generated)

## Deployment Strategy

### Step 1: Stop the Running Flutter Dev Server
- Kill the background `flutter run` process that's currently running in Chrome
- This ensures clean state for the production build

**Command:** `q` to quit the flutter run process, or kill the task with ID `beaf9cd`

### Step 2: Run the Firebase Deployment Script
- Execute: `cd chat_app && ./deploy.sh`
- Choose **Option 1** (use default Supabase values) when prompted
- The script will:
  1. Verify Firebase CLI is installed and user is logged in
  2. Confirm the default project (`smart-chat-78868`)
  3. Trigger the predeploy hook which runs `build.sh`
  4. Flutter builds the web app in release mode: `flutter build web --release --base-href="/"`
  5. Firebase deploys the `build/web/` directory to hosting
  6. Updates the `.firebase/hosting.YnVpbGQvd2Vi.cache` file

### Step 3: Verify Deployment Success
After deployment completes, verify:
1. **Build confirmation:** Script shows "✓ Deployment successful"
2. **Live URL accessible:** Visit https://smart-chat-78868.web.app
3. **New features working:** Test AI agent functionality, retry logic, offline detection
4. **No errors in console:** Check browser DevTools console for any runtime errors

### Step 4: (Optional) Commit the Updated Cache File
- The `.firebase/hosting.YnVpbGQvd2Vi.cache` file will be updated automatically
- Can commit this change to track deployment history, or leave it untracked

## Critical Files
- **Deployment script:** `chat_app/deploy.sh`
- **Build script:** `chat_app/build.sh`
- **Firebase config:** `firebase.json` (predeploy hook configured)
- **Project config:** `.firebaserc` (project ID: `smart-chat-78868`)
- **Web entry point:** `chat_app/web/index.html`
- **Supabase config:** `chat_app/lib/config/supabase_config.dart`

## Expected Outcome
- ✅ Latest `feature/agent-upgrade` code deployed to production
- ✅ Live at https://smart-chat-78868.web.app with all new features
- ✅ Build artifacts cached for fast page loads (1-year cache headers)
- ✅ Single Page App routing working correctly with SPA rewrite rules

## Rollback Plan
If needed, can redeploy the previous version by:
1. Switching to `main` branch: `git checkout main`
2. Running deployment again: `cd chat_app && ./deploy.sh`
3. Choose Option 1 when prompted

## Verification Checklist
- [ ] `flutter run` process stopped
- [ ] Deployment script runs successfully
- [ ] Firebase shows deployment complete with new file hashes
- [ ] Live URL loads without errors
- [ ] AI chat assist feature works
- [ ] Retry logic and offline detection function properly

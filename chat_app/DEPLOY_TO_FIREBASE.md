# Deploy to Firebase Hosting - Quick Start Guide

Follow these steps to deploy your Flutter web app to Firebase Hosting.

## Prerequisites

- ✅ Firebase account (sign up at https://firebase.google.com if needed)
- ✅ Your Supabase project URL and anon key
- ✅ Node.js installed (for Firebase CLI)
- ✅ Git repository (optional, for CI/CD)

## Step 1: Get Your Supabase Credentials

1. Go to your Supabase project: https://supabase.com/dashboard
2. Select your project
3. Go to **Settings** → **API**
4. Copy these two values:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon public** key (long string starting with `eyJ...`)

Keep these handy for Step 4.

## Step 2: Install Firebase CLI

Install the Firebase CLI globally using npm:

```bash
npm install -g firebase-tools
```

Verify installation:

```bash
firebase --version
```

## Step 3: Login to Firebase

Authenticate with your Google account:

```bash
firebase login
```

This will open a browser window for authentication. After logging in, you'll be authenticated in the CLI.

## Step 4: Create a Firebase Project

### Option A: Via Firebase Console (Recommended)

1. Go to https://console.firebase.google.com
2. Click **Add project** (or **Create a project**)
3. Enter a project name (e.g., `chat-app-web`)
4. Follow the setup wizard:
   - Disable Google Analytics (optional, not needed for hosting)
   - Click **Create project**
5. Wait for the project to be created
6. Click **Continue** to go to the project dashboard

### Option B: Via Firebase CLI

```bash
firebase projects:create chat-app-web
```

Replace `chat-app-web` with your desired project name.

## Step 5: Initialize Firebase Hosting

Navigate to your project directory:

```bash
cd /path/to/chat_app
```

Initialize Firebase Hosting:

```bash
firebase init hosting
```

**Follow these prompts:**

1. **Select an existing project or create a new one**
   - Choose the project you created in Step 4

2. **What do you want to use as your public directory?**
   - Enter: `build/web`
   - This is where Flutter builds the web app

3. **Configure as a single-page app (rewrite all urls to /index.html)?**
   - Answer: **Yes** (this is required for Flutter web apps)

4. **Set up automatic builds and deploys with GitHub?**
   - Answer: **No** (we'll set up CI/CD separately if needed)

5. **File build/web/index.html already exists. Overwrite?**
   - Answer: **No** (keep existing files)

The initialization will create:
- `firebase.json` - Already exists, but Firebase may update it
- `.firebaserc` - Stores your project configuration

**Note:** If you see a message about `firebase.json` already existing, that's fine - our configuration is already set up correctly.

## Step 6: Set Environment Variables

Before deploying, you need to set your Supabase credentials as environment variables.

### For Local Deployment:

Set environment variables in your terminal:

**On macOS/Linux:**
```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key-here"
```

**On Windows (PowerShell):**
```powershell
$env:SUPABASE_URL="https://your-project.supabase.co"
$env:SUPABASE_ANON_KEY="your-anon-key-here"
```

**On Windows (Command Prompt):**
```cmd
set SUPABASE_URL=https://your-project.supabase.co
set SUPABASE_ANON_KEY=your-anon-key-here
```

**Important:** These environment variables must be set in the same terminal session where you'll run `firebase deploy`.

### Verify Environment Variables:

```bash
echo $SUPABASE_URL
echo $SUPABASE_ANON_KEY
```

Both should show your values (not empty).

## Step 7: Deploy to Firebase Hosting

Deploy your app:

```bash
firebase deploy --only hosting
```

**What happens during deployment:**

1. Firebase runs the `predeploy` hook (executes `bash build.sh`)
2. The build script:
   - Checks for Flutter installation
   - Gets Flutter dependencies
   - Builds the web app with your environment variables
   - Verifies the build output
3. Firebase uploads the `build/web` directory to Firebase Hosting
4. Your app is deployed!

**First deployment may take 5-10 minutes** (installs Flutter SDK if needed). Subsequent deployments are faster (2-5 minutes).

## Step 8: Access Your Deployed App

After successful deployment, Firebase will show you a URL like:

```
https://your-project-id.web.app
```

or

```
https://your-project-id.firebaseapp.com
```

Open this URL in your browser to see your deployed app!

## Step 9: Verify Deployment

1. Visit your deployment URL
2. Test the app:
   - Try signing up/logging in
   - Verify Supabase connection works
   - Test basic functionality
   - Check that navigation works (no 404 errors)

## Troubleshooting

### Build Fails: "Flutter not found"

- **Solution**: The build script should auto-install Flutter. Check the build logs for errors.
- If it persists, ensure you have `git` installed (required for Flutter SDK installation).
- You can also install Flutter manually: https://docs.flutter.dev/get-started/install

### Build Fails: "Environment variables not set"

- **Solution**: 
  1. Verify environment variables are set: `echo $SUPABASE_URL`
  2. Make sure you set them in the same terminal session where you run `firebase deploy`
  3. On macOS/Linux, use `export`; on Windows, use `set` or `$env:`

### App Shows "Connection Error" or Can't Connect to Supabase

- **Solution**: 
  1. Verify environment variables were set correctly before deployment
  2. Check that your Supabase project is active
  3. Verify the anon key is correct (not the service_role key)
  4. Redeploy after fixing environment variables:
     ```bash
     export SUPABASE_URL="https://your-project.supabase.co"
     export SUPABASE_ANON_KEY="your-anon-key"
     firebase deploy --only hosting
     ```

### Build Takes Too Long

- **Normal**: First build installs Flutter SDK (5-10 minutes)
- **Subsequent builds**: Should be faster (2-5 minutes) due to caching
- If consistently slow, check build logs for errors

### Routes Don't Work (404 errors on navigation)

- **Solution**: 
  1. Verify `firebase.json` has the rewrites configuration (should be set automatically)
  2. Ensure `--base-href="/"` is in the build command (already in `build.sh`)
  3. Redeploy after configuration changes

### "Firebase project not found" Error

- **Solution**: 
  1. Verify you're logged in: `firebase login`
  2. List your projects: `firebase projects:list`
  3. If the project doesn't exist, create it in Firebase Console first
  4. Link to the correct project: `firebase use --add`

### "Permission denied" Error

- **Solution**: 
  1. Make sure you're logged in: `firebase login`
  2. Verify you have access to the Firebase project
  3. Check that you're using the correct project: `firebase use`

### Deployment URL Shows Blank Page

- **Solution**:
  1. Check Firebase Hosting logs in Firebase Console
  2. Verify `build/web/index.html` exists after build
  3. Check browser console for JavaScript errors
  4. Ensure environment variables were set during build

## Updating Your Deployment

Every time you want to update your deployment:

1. Set environment variables (if not already set):
   ```bash
   export SUPABASE_URL="https://your-project.supabase.co"
   export SUPABASE_ANON_KEY="your-anon-key"
   ```

2. Deploy:
   ```bash
   firebase deploy --only hosting
   ```

The build script runs automatically via the `predeploy` hook, so you don't need to run `build.sh` manually.

## Custom Domain (Optional)

To use a custom domain:

1. Go to Firebase Console → Your Project → Hosting
2. Click **Add custom domain**
3. Enter your domain name
4. Follow the DNS configuration instructions
5. Wait for DNS verification (can take a few minutes to 24 hours)
6. Your app will be available at your custom domain

**Note:** If using a custom domain at root path, the base-href in `build.sh` (`--base-href="/"`) is already correct.

## CI/CD Setup (Optional)

For automated deployments, see the GitHub Actions workflow in `.github/workflows/firebase_deploy.yml`. This will automatically deploy when you push to the main branch.

### Setting Up CI/CD:

1. Go to your GitHub repository
2. Add Firebase token as a secret:
   - Go to **Settings** → **Secrets and variables** → **Actions**
   - Click **New repository secret**
   - Name: `FIREBASE_TOKEN`
   - Value: Get it by running `firebase login:ci` locally
3. Ensure `SUPABASE_URL` and `SUPABASE_ANON_KEY` are already set as secrets
4. Push to main branch - deployment will trigger automatically

## Quick Reference

**Required Environment Variables:**
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anon public key

**Build Configuration:**
- Build Script: `bash build.sh` (runs automatically via predeploy hook)
- Output Directory: `build/web`
- Base Path: `/` (root)

**Deployment Command:**
```bash
firebase deploy --only hosting
```

**Deployment URL Format:**
- Production: `https://your-project-id.web.app`
- Alternative: `https://your-project-id.firebaseapp.com`

**Firebase CLI Commands:**
- Login: `firebase login`
- List projects: `firebase projects:list`
- Use project: `firebase use <project-id>`
- Deploy: `firebase deploy --only hosting`
- View logs: `firebase hosting:channel:list`

## Need Help?

- **Firebase Documentation**: https://firebase.google.com/docs/hosting
- **Flutter Web**: https://docs.flutter.dev/deployment/web
- **Firebase Console**: https://console.firebase.google.com
- **Firebase CLI Reference**: https://firebase.google.com/docs/cli

## Benefits of Firebase Hosting

- **Better Flutter Support**: Firebase Hosting is well-tested with Flutter web apps
- **Simpler Configuration**: No complex routing issues like GitHub Pages
- **Better Performance**: Firebase CDN with global distribution
- **Easier Debugging**: Clear deployment logs and error messages
- **Free Tier**: Generous free tier for hosting static sites
- **Automatic HTTPS**: SSL certificates provided automatically
- **Custom Domains**: Easy custom domain setup
- **Rollback Support**: Easy to rollback to previous deployments


# Migrate from Vercel to Firebase Hosting

This guide documents the steps to switch your deployment from Vercel to Firebase Hosting.

## ✅ Automated Changes (Already Completed)

The following changes have been made automatically:

1. **Removed `vercel.json`** - Prevents Vercel from auto-detecting and deploying your project
2. **Updated `build.sh`** - Removed Vercel-specific messaging
3. **Verified Firebase workflow** - Updated `firebase_deploy.yml` with explicit project ID

## 🔧 Manual Steps Required

### Step 1: Disconnect Vercel from GitHub

Vercel may still be connected to your GitHub repository via their integration. You need to disconnect it:

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Select your project (if you have multiple projects)
3. Navigate to **Settings** → **Git**
4. Click **Disconnect** or **Remove** to disconnect the GitHub repository
   - Alternatively, you can disable auto-deployments while keeping the connection

**Why this matters:** Even without `vercel.json`, if Vercel is connected via GitHub integration, it may still attempt to deploy. Disconnecting ensures Vercel won't deploy on pushes.

### Step 2: Verify GitHub Secrets

Your Firebase deployment workflow requires the following secrets in GitHub:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Verify the following secrets exist:

#### Required Secrets:

- **`FIREBASE_TOKEN`** - Firebase CI token for authentication
  - If missing, generate it by running locally:
    ```bash
    firebase login:ci
    ```
  - Copy the token and add it as a new repository secret named `FIREBASE_TOKEN`

- **`SUPABASE_URL`** - Your Supabase project URL
  - Format: `https://xxxxx.supabase.co`
  - Should already exist if you were deploying to Vercel

- **`SUPABASE_ANON_KEY`** - Your Supabase anonymous/public key
  - Should already exist if you were deploying to Vercel

### Step 3: Test the Firebase Deployment

After completing the manual steps above:

1. Push your changes to the `main` or `master` branch
2. Go to **Actions** tab in your GitHub repository
3. You should see the "Deploy to Firebase Hosting" workflow running
4. Monitor the workflow logs to ensure it completes successfully

### Step 4: Verify Deployment

Once the workflow completes:

1. Check the workflow logs for the deployment URL
2. Visit the Firebase Hosting URL (typically `https://smart-chat-78868.web.app`)
3. Verify your app is working correctly
4. Test key functionality (login, chat, etc.)

## 📋 Verification Checklist

Before considering the migration complete, verify:

- [ ] Vercel is disconnected from GitHub (or auto-deployments disabled)
- [ ] `FIREBASE_TOKEN` secret exists in GitHub
- [ ] `SUPABASE_URL` secret exists in GitHub
- [ ] `SUPABASE_ANON_KEY` secret exists in GitHub
- [ ] Firebase workflow runs successfully on push to main/master
- [ ] App is accessible at Firebase Hosting URL
- [ ] App functionality works correctly

## 🔄 Rollback (If Needed)

If you need to rollback to Vercel:

1. Reconnect Vercel in Vercel Dashboard
2. Restore `vercel.json` file (you can find it in git history)
3. Push changes to trigger Vercel deployment

## 📚 Additional Resources

- [Firebase Hosting Documentation](https://firebase.google.com/docs/hosting)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🆘 Troubleshooting

### Workflow Fails: "FIREBASE_TOKEN not set"
- **Solution**: Add the `FIREBASE_TOKEN` secret in GitHub repository settings
- Generate token: `firebase login:ci`

### Workflow Fails: "Project not found"
- **Solution**: Verify the project ID in `.firebaserc` matches your Firebase project
- Current project ID: `smart-chat-78868`

### Vercel Still Deploying
- **Solution**: Ensure you've disconnected the repository in Vercel Dashboard
- Check Vercel project settings to confirm auto-deployments are disabled

### Build Fails: Environment Variables
- **Solution**: Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set in GitHub Secrets
- The workflow will use default values from config if not set, but this may cause issues

## 📝 Notes

- The Firebase workflow uses the `predeploy` hook in `firebase.json` to automatically run `build.sh`
- Environment variables set in the workflow are passed to `build.sh` during the build process
- The workflow deploys to the project specified in `.firebaserc` (`smart-chat-78868`)
- Both `main` and `master` branches trigger deployments (if they exist)


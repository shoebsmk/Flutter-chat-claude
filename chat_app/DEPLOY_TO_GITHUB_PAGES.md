# Deploy to GitHub Pages - Quick Start Guide

Follow these steps to deploy your Flutter web app to GitHub Pages.

## Prerequisites

- ✅ GitHub account
- ✅ Your Supabase project URL and anon key
- ✅ Git repository on GitHub (this repository)
- ✅ Repository must be public (or GitHub Pro/Team/Enterprise account for private repos)

## Step 1: Get Your Supabase Credentials

1. Go to your Supabase project: https://supabase.com/dashboard
2. Select your project
3. Go to **Settings** → **API**
4. Copy these two values:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon public** key (long string starting with `eyJ...`)

Keep these handy for Step 2.

## Step 2: Configure GitHub Secrets

**IMPORTANT:** Do this before the first deployment!

GitHub Secrets store your Supabase credentials securely and are used by the GitHub Actions workflow.

### Via GitHub Web Interface:

1. Go to your repository on GitHub: `https://github.com/shoebsmk/Flutter-chat-claude`
2. Click **Settings** (top menu)
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add the first secret:
   - **Name**: `SUPABASE_URL`
   - **Value**: Paste your Supabase Project URL (e.g., `https://xxxxx.supabase.co`)
   - Click **Add secret**
6. Click **New repository secret** again
7. Add the second secret:
   - **Name**: `SUPABASE_ANON_KEY`
   - **Value**: Paste your Supabase anon public key
   - Click **Add secret**

### Via GitHub CLI (Alternative):

```bash
# Install GitHub CLI if not installed
# macOS: brew install gh
# Or download from: https://cli.github.com/

# Authenticate
gh auth login

# Set secrets
gh secret set SUPABASE_URL --repo shoebsmk/Flutter-chat-claude --body "https://your-project.supabase.co"
gh secret set SUPABASE_ANON_KEY --repo shoebsmk/Flutter-chat-claude --body "your-anon-key-here"
```

## Step 3: Enable GitHub Pages

1. Go to your repository on GitHub
2. Click **Settings** (top menu)
3. In the left sidebar, scroll down to **Pages**
4. Under **Source**, select:
   - **Source**: Deploy from a branch
   - **Branch**: `gh-pages`
   - **Folder**: `/ (root)`
5. Click **Save**

**Note:** The `gh-pages` branch will be automatically created by the GitHub Actions workflow on first deployment.

## Step 4: Commit and Push the Workflow

Make sure the GitHub Actions workflow file is committed and pushed:

```bash
# Check which files need to be committed
git status

# Add the workflow file
git add .github/workflows/deploy.yml

# Commit the changes
git commit -m "Add GitHub Pages deployment workflow"

# Push to your repository
git push origin main
```

## Step 5: Trigger Deployment

The workflow will automatically trigger when you push to the `main` branch. To trigger it manually:

1. Go to your repository on GitHub
2. Click **Actions** (top menu)
3. Select **Deploy to GitHub Pages** workflow from the left sidebar
4. Click **Run workflow** (top right)
5. Select the branch (usually `main`) and click **Run workflow**

## Step 6: Monitor Deployment

1. Go to **Actions** tab in your repository
2. Click on the running workflow to see real-time build logs
3. Wait for the build to complete (first build may take 5-10 minutes as it installs Flutter SDK)
4. Once complete, you'll see a green checkmark

## Step 7: Access Your Deployed App

After successful deployment, your app will be available at:

**https://shoebsmk.github.io/Flutter-chat-claude/**

**Note:** It may take a few minutes after deployment completes for GitHub Pages to update. You can check the deployment status in **Settings** → **Pages**.

## Step 8: Verify Deployment

1. Visit your deployment URL
2. Test the app:
   - Try signing up/logging in
   - Verify Supabase connection works
   - Test basic functionality

## Troubleshooting

### Build Fails: "Flutter not found"

- **Solution**: The workflow uses `subosito/flutter-action@v2` which should automatically install Flutter. Check the Actions logs to see if there's a specific error.
- If it persists, verify the workflow file syntax is correct.

### Build Fails: "Environment variables not set"

- **Solution**: 
  1. Go to **Settings** → **Secrets and variables** → **Actions**
  2. Verify both `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set
  3. Note: After adding secrets, you need to trigger a new workflow run
  4. Secrets are encrypted and cannot be viewed after creation (you can only update them)

### App Shows "Connection Error" or Can't Connect to Supabase

- **Solution**: 
  1. Verify GitHub Secrets are set correctly (re-add them if needed)
  2. Check that your Supabase project is active
  3. Verify the anon key is correct (not the service_role key)
  4. Trigger a new deployment after fixing secrets

### Build Takes Too Long

- **Normal**: First build installs Flutter SDK (5-10 minutes)
- **Subsequent builds**: Should be faster (2-5 minutes) due to caching
- If consistently slow, check build logs for errors

### Routes Don't Work (404 errors on navigation)

- **Solution**: 
  1. Verify the base-href is set to `/Flutter-chat-claude/` in the workflow
  2. The workflow already includes `--base-href="/Flutter-chat-claude/"` flag
  3. Ensure you're accessing the app at the correct URL (with trailing slash)

### "Pages build failed" Error

- **Solution**:
  1. Check the Actions logs for specific error messages
  2. Verify the workflow completed successfully before Pages tries to deploy
  3. Make sure `build/web` directory exists and contains `index.html`

### App Not Accessible After Deployment

- **Solution**:
  1. Wait a few minutes (GitHub Pages can take 1-5 minutes to update)
  2. Check **Settings** → **Pages** for deployment status
  3. Clear browser cache and try again
  4. Verify the URL is correct: `https://shoebsmk.github.io/Flutter-chat-claude/`

### GitHub Actions Not Running

- **Solution**:
  1. Verify `.github/workflows/deploy.yml` exists in your repository
  2. Check that the file is committed and pushed
  3. Go to **Settings** → **Actions** → **General** and ensure "Allow all actions and reusable workflows" is enabled

## Manual Deployment (Alternative)

If you prefer to deploy manually without GitHub Actions:

```bash
# Build the web app locally
flutter build web --release --base-href="/Flutter-chat-claude/"

# Initialize gh-pages branch (first time only)
git checkout --orphan gh-pages
git rm -rf .
cp -r build/web/* .
git add .
git commit -m "Initial GitHub Pages deployment"
git push origin gh-pages

# Switch back to main branch
git checkout main
```

**Note:** Manual deployment requires you to handle environment variables differently. You may need to update `lib/config/supabase_config.dart` directly (not recommended for production).

## Updating Your Deployment

Every time you push to the `main` branch, the workflow will automatically:
1. Build your Flutter web app
2. Deploy to the `gh-pages` branch
3. Update your GitHub Pages site

You don't need to do anything else - it's fully automated!

## Custom Domain (Optional)

If you want to use a custom domain:

1. Go to **Settings** → **Pages**
2. Scroll to **Custom domain** section
3. Enter your custom domain
4. Follow DNS configuration instructions
5. **Important**: Update the base-href in the workflow if using a custom domain at root path

## Quick Reference

**Required GitHub Secrets:**
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anon public key

**Deployment URL:**
- Production: `https://shoebsmk.github.io/Flutter-chat-claude/`

**Build Configuration:**
- Base path: `/Flutter-chat-claude/`
- Output directory: `build/web`
- Deploy branch: `gh-pages`

**Workflow Triggers:**
- Push to `main` branch
- Manual trigger via Actions tab

## Need Help?

- **GitHub Pages Documentation**: https://docs.github.com/en/pages
- **GitHub Actions Documentation**: https://docs.github.com/en/actions
- **Flutter Web**: https://docs.flutter.dev/deployment/web
- **GitHub Actions Logs**: Go to **Actions** tab → Click on a workflow run → View logs


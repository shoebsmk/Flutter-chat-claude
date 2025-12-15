# Deploy to Vercel - Quick Start Guide

Follow these steps to deploy your Flutter web app to Vercel.

## Prerequisites

- ✅ Vercel account (sign up at https://vercel.com if needed)
- ✅ Your Supabase project URL and anon key
- ✅ Git repository (GitHub, GitLab, or Bitbucket)

## Step 1: Get Your Supabase Credentials

1. Go to your Supabase project: https://supabase.com/dashboard
2. Select your project
3. Go to **Settings** → **API**
4. Copy these two values:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon public** key (long string starting with `eyJ...`)

Keep these handy for Step 3.

## Step 2: Connect Your Repository to Vercel

### Option A: Via Vercel Dashboard (Recommended)

1. Go to https://vercel.com/new
2. Click **Import Git Repository**
3. Select your Git provider (GitHub, GitLab, or Bitbucket)
4. Authorize Vercel if prompted
5. Select your `chat_app` repository
6. Click **Import**

### Option B: Via Vercel CLI

```bash
# Install Vercel CLI (if not installed)
npm i -g vercel

# Login to Vercel
vercel login

# Link your project
cd /path/to/chat_app
vercel link
```

## Step 3: Configure Environment Variables

**IMPORTANT:** Do this before deploying!

### In Vercel Dashboard:

1. After importing your project, you'll see the **Configure Project** page
2. Scroll down to **Environment Variables** section
3. Add the first variable:
   - **Key**: `SUPABASE_URL`
   - **Value**: Paste your Supabase Project URL
   - **Environments**: Check all (Production, Preview, Development)
   - Click **Add**
4. Add the second variable:
   - **Key**: `SUPABASE_ANON_KEY`
   - **Value**: Paste your Supabase anon public key
   - **Environments**: Check all (Production, Preview, Development)
   - Click **Add**

### Via Vercel CLI:

```bash
vercel env add SUPABASE_URL
# Paste your Supabase URL when prompted
# Select: Production, Preview, Development

vercel env add SUPABASE_ANON_KEY
# Paste your anon key when prompted
# Select: Production, Preview, Development
```

## Step 4: Configure Project Settings

In the Vercel dashboard **Configure Project** page:

1. **Framework Preset**: Select **Other** (or leave as auto-detected)
2. **Root Directory**: Leave as `./` (project root)
3. **Build Command**: Should auto-detect as `bash build.sh` (from `vercel.json`)
4. **Output Directory**: Should auto-detect as `build/web` (from `vercel.json`)
5. **Install Command**: Leave empty (handled by build script)

**Note:** If settings don't auto-detect, manually set:
- Build Command: `bash build.sh`
- Output Directory: `build/web`

## Step 5: Commit and Push Configuration Files

**IMPORTANT:** Before deploying, make sure these files are committed and pushed to your repository:

```bash
# Check which files need to be committed
git status

# Add the configuration files
git add vercel.json build.sh VERCEL_DEPLOYMENT.md DEPLOY_TO_VERCEL.md

# Commit the changes
git commit -m "Add Vercel deployment configuration"

# Push to your repository
git push
```

**Why this matters:** Vercel builds from your Git repository. If `vercel.json` and `build.sh` aren't in the repo, Vercel won't have the correct build configuration and you'll get 404 errors.

## Step 6: Deploy

1. Go to your Vercel project dashboard
2. If you just pushed, Vercel should automatically trigger a new deployment
3. Or manually click **Deploy** button
4. Wait for the build to complete (first build may take 5-10 minutes as it installs Flutter SDK)
5. Once complete, you'll see a success message with your deployment URL

## Step 7: Verify Deployment

1. Click on your deployment URL to open the app
2. Test the app:
   - Try signing up/logging in
   - Verify Supabase connection works
   - Test basic functionality

## Troubleshooting

### 404 NOT_FOUND Error (Most Common)

If you see a 404 error when accessing your deployed app:

👉 **See detailed troubleshooting guide:** [VERCEL_404_TROUBLESHOOTING.md](VERCEL_404_TROUBLESHOOTING.md)

**Quick fixes:**

1. **Check if configuration files are in your repository:**
   - Go to your Git repository (GitHub/GitLab/Bitbucket)
   - Verify `vercel.json` and `build.sh` exist in the root directory
   - **If they're missing:** Commit and push them, then redeploy
   
2. **Verify build output in Vercel logs:**
   - Go to Vercel dashboard → **Deployments** → Click on deployment → **Build Logs**
   - Look for "✅ Verified: index.html exists in build/web"
   - If you see "❌ ERROR: index.html not found", the build failed
   
3. **Check Vercel project settings:**
   - Go to **Settings** → **General**
   - Verify **Output Directory** is `build/web`
   - Verify **Build Command** is `bash build.sh`
   
4. **Redeploy after configuration changes:**
   - If you just added/updated `vercel.json` or `build.sh`, push the changes
   - Go to your Vercel project → **Deployments** tab
   - Click **Redeploy** on the latest deployment, or push a new commit to trigger a rebuild
   - **Clear build cache** before redeploying (Settings → General → Clear Build Cache)

2. **Verify build output:**
   - Check build logs in Vercel dashboard
   - Ensure `build/web` directory contains `index.html`
   - Verify the build completed successfully

3. **Check base href:**
   - The build script now includes `--base-href="/"` flag
   - This ensures Flutter web app uses root path correctly

4. **Verify vercel.json:**
   - Ensure `vercel.json` is in the project root
   - Check that `outputDirectory` is set to `build/web`
   - Verify rewrites are configured to send all routes to `/index.html`

5. **Clear cache and redeploy:**
   - In Vercel dashboard → Settings → General
   - Clear build cache
   - Trigger a new deployment

### Build Fails: "Flutter not found"
- **Solution**: The build script should auto-install Flutter. Check build logs for errors.
- If it persists, the build environment may need git access. Contact Vercel support.

### Build Fails: "Environment variables not set"
- **Solution**: Go to Project Settings → Environment Variables and verify both variables are set.
- Make sure they're enabled for the correct environment (Production/Preview/Development).

### App Shows "Connection Error" or Can't Connect to Supabase
- **Solution**: 
  1. Verify environment variables are set correctly in Vercel
  2. Check that your Supabase project is active
  3. Verify the anon key is correct (not the service_role key)
  4. Redeploy after fixing environment variables

### Build Takes Too Long
- **Normal**: First build installs Flutter SDK (5-10 minutes)
- **Subsequent builds**: Should be faster (2-5 minutes) due to caching
- If consistently slow, check build logs for errors

### Routes Don't Work (404 errors on navigation)
- **Solution**: 
  1. Verify `vercel.json` has the rewrites configuration
  2. Ensure `--base-href="/"` is in the build command (already added)
  3. Redeploy after configuration changes

## Next Steps

### Custom Domain (Optional)

1. Go to your project in Vercel Dashboard
2. Click **Settings** → **Domains**
3. Add your custom domain
4. Follow DNS configuration instructions

### Monitor Deployments

- View all deployments in your Vercel dashboard
- Set up deployment notifications
- Check build logs for any issues

## Quick Reference

**Required Environment Variables:**
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anon public key

**Build Configuration:**
- Build Command: `bash build.sh`
- Output Directory: `build/web`
- Framework: Other (Flutter)

**Deployment URL Format:**
- Production: `https://your-project.vercel.app`
- Preview: `https://your-project-git-branch.vercel.app`

## Need Help?

- **Vercel Documentation**: https://vercel.com/docs
- **Flutter Web**: https://docs.flutter.dev/deployment/web
- **Full Deployment Guide**: See `VERCEL_DEPLOYMENT.md` for detailed information


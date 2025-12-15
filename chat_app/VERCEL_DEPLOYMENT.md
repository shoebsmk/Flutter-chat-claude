# Vercel Deployment Guide

This guide explains how to deploy the SmartChat Flutter web app to Vercel.

## Prerequisites

- A Vercel account (sign up at https://vercel.com)
- A Supabase project with API keys
- Git repository (GitHub, GitLab, or Bitbucket) connected to Vercel

## Environment Variables

Before deploying, you need to configure the following environment variables in your Vercel project:

### Required Environment Variables

1. **SUPABASE_URL**
   - Description: Your Supabase project URL
   - Example: `https://your-project.supabase.co`
   - How to get it: Supabase Dashboard → Project Settings → API → Project URL

2. **SUPABASE_ANON_KEY**
   - Description: Your Supabase anonymous (public) key
   - Example: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - How to get it: Supabase Dashboard → Project Settings → API → Project API keys → `anon` `public` key

### Setting Environment Variables in Vercel

#### Via Vercel Dashboard:

1. Go to your project in Vercel Dashboard
2. Navigate to **Settings** → **Environment Variables**
3. Add each variable:
   - **Name**: `SUPABASE_URL`
   - **Value**: Your Supabase project URL
   - **Environment**: Production, Preview, and Development (select all)
4. Repeat for `SUPABASE_ANON_KEY`
5. Click **Save**

#### Via Vercel CLI:

```bash
vercel env add SUPABASE_URL
vercel env add SUPABASE_ANON_KEY
```

## Deployment Steps

### Option 1: Deploy via Vercel Dashboard (Recommended)

1. **Connect your repository:**
   - Go to https://vercel.com/new
   - Import your Git repository
   - Vercel will auto-detect the project settings

2. **Configure project settings:**
   - **Framework Preset**: Other
   - **Root Directory**: `./` (project root)
   - **Build Command**: `bash build.sh` (already configured in `vercel.json`)
   - **Output Directory**: `build/web` (already configured in `vercel.json`)
   - **Install Command**: Leave empty (handled by build script)

3. **Add environment variables:**
   - Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` as described above

4. **Deploy:**
   - Click **Deploy**
   - Wait for the build to complete

### Option 2: Deploy via Vercel CLI

1. **Install Vercel CLI:**
   ```bash
   npm i -g vercel
   ```

2. **Login to Vercel:**
   ```bash
   vercel login
   ```

3. **Link your project:**
   ```bash
   vercel link
   ```

4. **Set environment variables:**
   ```bash
   vercel env add SUPABASE_URL
   vercel env add SUPABASE_ANON_KEY
   ```

5. **Deploy:**
   ```bash
   vercel --prod
   ```

## Build Process

The build process is handled by `build.sh` script:

1. **Checks for Flutter SDK** - Installs if not present
2. **Gets dependencies** - Runs `flutter pub get`
3. **Builds web app** - Runs `flutter build web --release` with environment variables
4. **Outputs to** - `build/web` directory

### Build Configuration

The build script automatically:
- Installs Flutter SDK if not available
- Uses environment variables for Supabase configuration
- Falls back to default values if environment variables are not set (not recommended for production)

## Project Structure

```
chat_app/
├── vercel.json          # Vercel configuration
├── build.sh             # Build script
├── build/web/           # Build output (generated, in .gitignore)
└── ...
```

## Troubleshooting

### Build Fails: Flutter Not Found

If the build fails because Flutter is not found:
- The build script should automatically install Flutter
- Check build logs for any errors during Flutter installation
- Ensure the build environment has git and bash available

### Build Fails: Environment Variables Not Set

If you see warnings about missing environment variables:
- Verify environment variables are set in Vercel dashboard
- Ensure variables are available for the correct environment (Production/Preview/Development)
- Redeploy after adding environment variables

### App Not Loading: Routing Issues

If the app doesn't load on certain routes:
- Verify `vercel.json` has the correct rewrites configuration
- All routes should redirect to `index.html` for SPA routing

### Build Timeout

If builds timeout:
- Flutter SDK installation can take time on first build
- Subsequent builds should be faster due to caching
- Consider using Vercel's build cache

## Post-Deployment

After successful deployment:

1. **Test the application:**
   - Visit your Vercel deployment URL
   - Test authentication flow
   - Verify Supabase connection

2. **Configure custom domain (optional):**
   - Go to Project Settings → Domains
   - Add your custom domain
   - Configure DNS as instructed

3. **Monitor deployments:**
   - Check Vercel dashboard for deployment status
   - Review build logs for any issues
   - Set up deployment notifications if needed

## Security Notes

- Never commit Supabase credentials to version control
- Always use environment variables for sensitive data
- The `anon` key is safe to expose in client-side code (it's public)
- Consider enabling Row Level Security (RLS) in Supabase for additional security

## Additional Resources

- [Vercel Documentation](https://vercel.com/docs)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Supabase Documentation](https://supabase.com/docs)


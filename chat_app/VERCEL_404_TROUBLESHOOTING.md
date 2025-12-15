# Vercel 404 Error - Troubleshooting Guide

If you're still getting a 404 error after deploying, follow these steps:

## Step 1: Verify Build Output

Check your Vercel build logs to ensure:

1. **Build completed successfully**
   - Look for "✅ Build completed successfully!" in logs
   - No error messages at the end

2. **index.html exists**
   - Look for "✅ Verified: index.html exists in build/web" in logs
   - If you see "❌ ERROR: index.html not found", the build failed

3. **Output directory is correct**
   - Verify logs show "📦 Output directory: build/web"
   - Check that files are listed after build

## Step 2: Check Vercel Project Settings

In your Vercel project dashboard:

1. Go to **Settings** → **General**
2. Verify:
   - **Build Command**: `bash build.sh` (or auto-detected)
   - **Output Directory**: `build/web` (or auto-detected)
   - **Root Directory**: `./` (project root)

3. If settings are wrong:
   - Update them manually
   - Save changes
   - Redeploy

## Step 3: Verify vercel.json is in Repository

1. Go to your Git repository (GitHub/GitLab/Bitbucket)
2. Check that `vercel.json` exists in the **root directory**
3. Verify it contains the rewrites configuration:
   ```json
   {
     "rewrites": [
       {
         "source": "/(.*)",
         "destination": "/index.html"
       }
     ]
   }
   ```

4. If `vercel.json` is missing or incorrect:
   ```bash
   git add vercel.json
   git commit -m "Add vercel.json configuration"
   git push
   ```

## Step 4: Check Deployment URL

**Important:** Are you getting 404 on:
- **Root URL** (e.g., `https://your-app.vercel.app/`)? → See Step 5
- **Specific route** (e.g., `https://your-app.vercel.app/chat`)? → This is expected if routing isn't configured

## Step 5: Verify Build Output Structure

In Vercel build logs, you should see files like:
```
index.html
main.dart.js
flutter_bootstrap.js
assets/
canvaskit/
icons/
```

If these files are missing, the build didn't complete correctly.

## Step 6: Clear Cache and Redeploy

1. In Vercel dashboard → **Settings** → **General**
2. Scroll to **Build Cache**
3. Click **Clear Build Cache**
4. Go to **Deployments** tab
5. Click **Redeploy** on latest deployment

## Step 7: Check Environment Variables

If build succeeds but app shows connection errors:

1. Go to **Settings** → **Environment Variables**
2. Verify:
   - `SUPABASE_URL` is set
   - `SUPABASE_ANON_KEY` is set
   - Both are enabled for **Production**, **Preview**, and **Development**

3. After adding/updating variables:
   - **Redeploy** (environment variables require a new deployment)

## Step 8: Test Locally First

Before deploying, test the build locally:

```bash
# Build locally
bash build.sh

# Check output
ls -la build/web/

# Verify index.html exists
test -f build/web/index.html && echo "✅ index.html exists" || echo "❌ Missing!"
```

If local build fails, fix issues before deploying.

## Step 9: Check Vercel Build Logs

In Vercel dashboard → **Deployments** → Click on a deployment → **Build Logs**:

Look for:
- ✅ Success messages
- ❌ Error messages
- Warnings about missing files
- Flutter installation messages
- Build completion confirmation

## Step 10: Alternative Configuration

If the standard configuration doesn't work, try this alternative `vercel.json`:

```json
{
  "buildCommand": "bash build.sh",
  "outputDirectory": "build/web",
  "cleanUrls": true,
  "trailingSlash": false,
  "rewrites": [
    {
      "source": "/:path*",
      "destination": "/index.html"
    }
  ]
}
```

## Common Issues and Solutions

### Issue: "Build succeeded but 404 on root URL"
**Solution:**
- Verify `vercel.json` is in repository root
- Check that `outputDirectory` is exactly `build/web`
- Ensure rewrites configuration is present
- Clear cache and redeploy

### Issue: "404 on specific routes but root works"
**Solution:**
- This means rewrites aren't working
- Verify `vercel.json` rewrites configuration
- Check that you're not using a custom domain with path issues

### Issue: "Build fails with 'Flutter not found'"
**Solution:**
- Build script should auto-install Flutter
- Check build logs for installation errors
- Verify git is available in build environment
- Contact Vercel support if issue persists

### Issue: "Files exist but still 404"
**Solution:**
- Check Vercel project settings match `vercel.json`
- Verify output directory is correct
- Try clearing build cache
- Check if there are conflicting configurations

## Still Not Working?

If none of these steps work:

1. **Check Vercel Status**: https://vercel-status.com
2. **Review Vercel Documentation**: https://vercel.com/docs
3. **Check Build Logs**: Look for specific error messages
4. **Contact Support**: Vercel support or Flutter community

## Quick Diagnostic Checklist

- [ ] `vercel.json` exists in repository root
- [ ] `build.sh` exists and is executable
- [ ] Build completes successfully in Vercel logs
- [ ] `index.html` exists in build output
- [ ] Output directory is `build/web`
- [ ] Rewrites are configured in `vercel.json`
- [ ] Environment variables are set
- [ ] Cache cleared and redeployed
- [ ] Project settings match configuration

If all checkboxes are checked and still getting 404, the issue might be:
- Vercel platform issue (check status page)
- Network/CDN caching (wait a few minutes)
- Browser cache (try incognito/private mode)



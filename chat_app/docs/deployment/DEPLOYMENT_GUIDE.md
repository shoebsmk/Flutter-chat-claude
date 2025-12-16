# Deployment Guide for AI Command Feature

## Setting Up Gemini API Key

### Method 1: Via Supabase Dashboard (Recommended)

1. Go to your Supabase project dashboard:
   https://supabase.com/dashboard/project/djpzzwjxjlslnkgstgfk/settings/functions

2. Navigate to **Settings** → **Edge Functions** → **Secrets**

3. Click **Add Secret** and enter:
   - **Name**: `GEMINI_API_KEY`
   - **Value**: Your Gemini API key (get it from https://aistudio.google.com/app/apikey)

4. Click **Save**

### Method 2: Via Supabase CLI

```bash
# 1. Login to Supabase CLI
npx supabase login

# 2. Link to your project (if not already linked)
npx supabase link --project-ref djpzzwjxjlslnkgstgfk

# 3. Set the secret
npx supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here
```

## Deploying the Edge Function

### Via Supabase Dashboard

1. Go to **Edge Functions** in your Supabase dashboard
2. Click **Deploy new function**
3. Upload or paste the contents of `supabase/functions/extract-message-intent/index.ts`
4. Name it `extract-message-intent`

### Via Supabase CLI

```bash
# Make sure you're logged in and linked
npx supabase login
npx supabase link --project-ref djpzzwjxjlslnkgstgfk

# Deploy the function
npx supabase functions deploy extract-message-intent
```

## Testing the Function

After deployment, you can test it:

```bash
# Test locally (if running local Supabase)
curl -X POST http://localhost:54321/functions/v1/extract-message-intent \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"command": "Send Ahmed I'\''ll be late"}'
```

Or test via the Flutter app:
1. Run the app
2. Navigate to "AI Assistant" tab
3. Try: "Send Ahmed I'll be late"

## Troubleshooting

### "Command not found: supabase"
Use `npx supabase` instead of `supabase`

### "Access token not provided"
Run `npx supabase login` first

### "Failed to extract intent"
- Check that GEMINI_API_KEY is set correctly
- Verify the Edge Function is deployed
- Check Edge Function logs in Supabase dashboard
- The function uses automatic model fallback, so check logs for which models were attempted

### "AI service not configured"
- Ensure `GEMINI_API_KEY` secret is set in Supabase
- Verify the secret name is exactly `GEMINI_API_KEY` (case-sensitive)

## Edge Function Features

The deployed Edge Function includes:
- **Automatic Model Fallback**: Tries multiple Gemini API versions/models for reliability
- **Input Validation**: Commands limited to 500 characters
- **CORS Support**: Handles cross-origin requests
- **Robust Error Handling**: Clear error messages and appropriate HTTP status codes
- **JSON Parsing**: Handles various response formats including markdown code blocks

See `supabase/functions/extract-message-intent/README.md` for complete documentation.


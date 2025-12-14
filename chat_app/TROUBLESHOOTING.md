# Troubleshooting AI Command Feature

## Error: "Failed to extract intent" (500 Error)

This error indicates the Edge Function is running but encountering an issue. Here's how to diagnose and fix it:

### Step 1: Check if GEMINI_API_KEY is Set

1. Go to your Supabase Dashboard
2. Navigate to **Settings** → **Edge Functions** → **Secrets**
3. Verify that `GEMINI_API_KEY` exists and has a valid value
4. If missing, add it:
   - **Name**: `GEMINI_API_KEY`
   - **Value**: Your Gemini API key (from https://aistudio.google.com/app/apikey)

### Step 2: Check Edge Function Logs

1. Go to **Edge Functions** in Supabase Dashboard
2. Click on `extract-message-intent`
3. Go to **Logs** tab
4. Look for error messages that will show:
   - If API key is missing
   - If Gemini API returned an error
   - If there's a parsing issue

### Step 3: Verify Gemini API Key

1. Test your API key directly:
   ```bash
   curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=YOUR_API_KEY" \
     -H 'Content-Type: application/json' \
     -d '{"contents":[{"parts":[{"text":"Hello"}]}]}'
   ```

2. If you get an error, your API key might be:
   - Invalid
   - Expired
   - Not activated
   - Restricted (check API restrictions in Google Cloud Console)

### Step 4: Redeploy the Function

After setting/changing the secret, you may need to redeploy:

```bash
npx supabase functions deploy extract-message-intent
```

Or via Dashboard:
1. Go to **Edge Functions**
2. Click on `extract-message-intent`
3. Click **Redeploy**

### Common Issues

#### Issue: "AI service not configured"
**Solution**: Set the `GEMINI_API_KEY` secret in Supabase

#### Issue: "Gemini API error: API key not valid"
**Solution**: 
- Verify your API key is correct
- Check if API key has restrictions
- Generate a new API key if needed

#### Issue: "Invalid response from AI"
**Solution**: 
- Check Edge Function logs for the actual response
- The Gemini API response format might have changed
- Try the function again (could be a transient error)

#### Issue: "Failed to parse AI response"
**Solution**: 
- Check Edge Function logs to see the raw response
- The AI might be returning non-JSON content
- This is usually a transient issue - try again

### Step 5: Test the Function Directly

You can test the Edge Function using curl:

```bash
curl -X POST https://djpzzwjxjlslnkgstgfk.supabase.co/functions/v1/extract-message-intent \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"command": "Send Ahmed I'\''ll be late"}'
```

Replace `YOUR_ANON_KEY` with your Supabase anon key.

### Getting More Debug Information

The updated Edge Function now provides more detailed error messages. Check:
1. **Flutter app console** - Shows the error message from Edge Function
2. **Supabase Edge Function logs** - Shows detailed server-side errors
3. **Network tab in browser** - Shows the actual HTTP response

### Still Having Issues?

1. Check that the Edge Function is deployed correctly
2. Verify the function name matches: `extract-message-intent`
3. Ensure you're using the correct Supabase project
4. Check if there are any rate limits on your Gemini API key




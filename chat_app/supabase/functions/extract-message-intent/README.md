# Extract Message Intent Edge Function

This Supabase Edge Function extracts recipient and message from natural language commands using Google Gemini API.

## Setup

### 1. Get Gemini API Key

1. Go to https://aistudio.google.com/app/apikey
2. Create a new API key
3. Copy the API key

### 2. Set Secret in Supabase

```bash
# Using Supabase CLI
supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here

# Or via Supabase Dashboard:
# Go to Project Settings > Edge Functions > Secrets
# Add GEMINI_API_KEY with your API key value
```

### 3. Deploy the Function

```bash
# Using Supabase CLI
supabase functions deploy extract-message-intent

# Or via Supabase Dashboard:
# Go to Edge Functions > Deploy new function
# Upload the function directory
```

## Testing

You can test the function locally using:

```bash
# Start Supabase locally
supabase start

# Test the function
curl -X POST http://localhost:54321/functions/v1/extract-message-intent \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"command": "Send Ahmed I'\''ll be late"}'
```

## API

### Request

```json
{
  "command": "Send Ahmed I'll be late"
}
```

### Response

```json
{
  "recipient_query": "Ahmed",
  "message": "I'll be late"
}
```

## Error Handling

The function returns appropriate HTTP status codes:
- `400`: Invalid input (missing command, too long, etc.)
- `500`: Server error (API key missing, Gemini API error, etc.)

## Cost Considerations

- Uses `gemini-1.5-flash` model (fast and cost-effective)
- Estimated cost: ~$0.00001 per request
- Free tier: 60 requests/minute


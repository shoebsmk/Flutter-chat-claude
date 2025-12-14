# Extract Message Intent Edge Function

This Supabase Edge Function extracts recipient and message from natural language commands using Google Gemini API. It features automatic model fallback, robust error handling, and CORS support.

## Features

- **Natural Language Processing**: Extracts recipient and message from commands like "Send Ahmed I'll be late"
- **Model Fallback**: Automatically tries multiple Gemini API versions and models for reliability
- **Input Validation**: Validates command length (max 500 characters) and format
- **CORS Support**: Handles cross-origin requests
- **Robust JSON Parsing**: Handles markdown code blocks and various response formats
- **Comprehensive Error Handling**: Provides clear error messages with appropriate HTTP status codes

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

### Local Testing

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

### Example Commands

The function can handle various command formats:

```json
{"command": "Send Ahmed I'll be late"}
{"command": "Message John Hello there"}
{"command": "Tell Sarah Meeting cancelled"}
```

## API

### Request

```json
{
  "command": "Send Ahmed I'll be late"
}
```

**Request Constraints:**
- `command` (required): String, max 500 characters
- Must be a non-empty string after trimming

### Response

**Success Response (200 OK):**
```json
{
  "recipient_query": "Ahmed",
  "message": "I'll be late"
}
```

**Error Response (400 Bad Request):**
```json
{
  "error": "Command is required"
}
```

```json
{
  "error": "Command is too long (max 500 characters)"
}
```

**Error Response (500 Internal Server Error):**
```json
{
  "error": "AI service not configured. Please set GEMINI_API_KEY secret."
}
```

```json
{
  "error": "Gemini API error: [specific error message]"
}
```

## Implementation Details

### Model Fallback Strategy

The function automatically tries multiple Gemini API configurations in order:

1. `gemini-1.5-flash` with API v1
2. `gemini-1.5-flash` with API v1beta
3. `gemini-pro` with API v1
4. `gemini-pro` with API v1beta

This ensures reliability even if specific models or API versions are temporarily unavailable.

### AI Prompt Strategy

The function uses a carefully crafted prompt with:
- Low temperature (0.1) for consistent extraction
- JSON-only response mode (`responseMimeType: 'application/json'`)
- Clear examples in the prompt
- Explicit format requirements

### JSON Parsing

The function handles various response formats:
- Pure JSON responses
- JSON wrapped in markdown code blocks (```json ... ```)
- Leading/trailing whitespace

## Error Handling

The function returns appropriate HTTP status codes:

- **400 Bad Request**: 
  - Missing or empty command
  - Command exceeds 500 character limit
  - Invalid input type

- **500 Internal Server Error**:
  - `GEMINI_API_KEY` secret not configured
  - All Gemini API model attempts failed
  - JSON parsing errors
  - Internal server errors

All errors include descriptive messages to help with debugging.

## CORS Support

The function handles CORS preflight requests:
- Responds to `OPTIONS` requests with appropriate headers
- Allows `POST` and `OPTIONS` methods
- Allows necessary headers: `authorization`, `x-client-info`, `apikey`, `content-type`
- Sets `Access-Control-Allow-Origin: *` on all responses

## Cost Considerations

- **Primary Model**: `gemini-1.5-flash` (fast and cost-effective)
- **Fallback Models**: `gemini-pro` (used only if flash fails)
- **Token Usage**: ~50-100 tokens per request (very low)
- **Estimated Cost**: ~$0.00001 per request
- **Free Tier**: 60 requests/minute (Gemini free tier)

The function is designed to be cost-effective by:
- Using the flash model first (cheaper)
- Low temperature setting (reduces token variance)
- Compact prompts
- Efficient JSON-only responses

## Security

- **API Key Security**: API key stored in Supabase secrets, never exposed to client
- **Input Validation**: Command length limited to prevent abuse
- **Error Messages**: Generic error messages prevent information leakage
- **Authentication**: Can be enhanced with auth token verification (optional)

## Performance

- **Response Time**: Typically 1-3 seconds (depending on Gemini API)
- **Timeout**: Consider setting client-side timeout (recommended: 10 seconds)
- **Edge Location**: Deployed on Supabase Edge for low latency

## Troubleshooting

### "AI service not configured" Error

Ensure the `GEMINI_API_KEY` secret is set:
```bash
supabase secrets set GEMINI_API_KEY=your_key_here
```

### "All model attempts failed" Error

- Verify your API key is valid and has quota remaining
- Check Gemini API status
- Ensure your Supabase project has network access

### JSON Parsing Errors

The function includes robust JSON parsing that handles:
- Markdown code blocks
- Extra whitespace
- Various formatting issues

If you still encounter parsing errors, check the function logs for the raw AI response.


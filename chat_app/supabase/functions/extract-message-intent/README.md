# Extract Message Intent Edge Function

This Supabase Edge Function extracts recipient and message from natural language commands using multiple AI providers (Gemini and OpenAI). It features automatic model fallback, provider switching, robust error handling, and CORS support.

## Features

- **Multi-Provider Support**: Switch between Gemini and OpenAI
- **Natural Language Processing**: Extracts recipient and message from commands like "Send Ahmed I'll be late"
- **Model Fallback**: Automatically tries multiple models for reliability
- **Provider Fallback**: Automatic fallback to secondary provider if primary fails
- **Input Validation**: Validates command length (max 500 characters) and format
- **CORS Support**: Handles cross-origin requests
- **Robust JSON Parsing**: Handles markdown code blocks and various response formats
- **Comprehensive Error Handling**: Provides clear error messages with appropriate HTTP status codes

## Setup

### Option 1: Using OpenAI (Default)

1. Get OpenAI API Key:
   - Go to https://platform.openai.com/api-keys
   - Create a new API key
   - Copy the API key

2. Set Secret in Supabase:
```bash
# Using Supabase CLI
supabase secrets set ChatApp=your_openai_api_key_here

# Or via Supabase Dashboard:
# Go to Project Settings > Edge Functions > Secrets
# Add ChatApp with your API key value
```

**Default Model:** `gpt-5-nano` (automatically used)

### Option 2: Using Gemini

1. Get Gemini API Key:
   - Go to https://aistudio.google.com/app/apikey
   - Create a new API key
   - Copy the API key

2. Set Secrets in Supabase:
```bash
# Using Supabase CLI
supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here
supabase secrets set AI_PROVIDER=gemini  # Set Gemini as provider

# Or via Supabase Dashboard:
# Go to Project Settings > Edge Functions > Secrets
# Add GEMINI_API_KEY with your API key value
# Add AI_PROVIDER=gemini to use Gemini instead of OpenAI
```

### Option 3: Configure Both Providers (with Fallback)

Set up both providers for automatic fallback:
```bash
supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here
supabase secrets set ChatApp=your_openai_api_key_here
supabase secrets set AI_PROVIDER=openai  # Primary provider (default)
supabase secrets set AI_FALLBACK_PROVIDER=gemini  # Fallback provider
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

**Basic Request:**
```json
{
  "command": "Send Ahmed I'll be late"
}
```

**Request with Provider Selection:**
```json
{
  "command": "Send Ahmed I'll be late",
  "provider": "openai"
}
```

**Request with Provider and Model Selection:**
```json
{
  "command": "Send Ahmed I'll be late",
  "provider": "openai",
  "model": "gpt-5-nano"
}
```

**Request Parameters:**
- `command` (required): String, max 500 characters, must be a non-empty string after trimming
- `provider` (optional): String, either `"gemini"` or `"openai"`. Defaults to `AI_PROVIDER` env var or `"openai"`
- `model` (optional): String, specific model name to use. If not provided, uses default model list for the provider

**Supported Providers:**
- `openai`: OpenAI API (default)
- `gemini`: Google Gemini API

**Supported Models:**

*Gemini Models:*
- `gemini-2.5-flash-lite` (default, tried first)
- `gemini-2.5-flash`
- `gemini-2.5-pro`
- `gemini-3-pro-preview`

*OpenAI Models:*
- `gpt-5-nano` (default, tried first)
- `gpt-4.1-nano-2025-04-14`
- `gpt-5-nano-2025-08-07`
- `gpt-4.1-nano`

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
  "error": "GEMINI_API_KEY not configured. Please set the secret."
}
```

```json
{
  "error": "ChatApp secret not configured. Please set the secret with your OpenAI API key."
}
```

```json
{
  "error": "Unsupported provider: anthropic. Supported providers: 'gemini', 'openai'"
}
```

```json
{
  "error": "Gemini API error: [specific error message]"
}
```

```json
{
  "error": "OpenAI API error: [specific error message]"
}
```

```json
{
  "error": "Primary provider failed: [error]. Fallback also failed: [error]"
}
```

## Implementation Details

### Provider Selection

The function selects the AI provider in this order:
1. `provider` parameter in the request (if provided)
2. `AI_PROVIDER` environment variable (if set)
3. Default: `"openai"` (with `gpt-5-nano` model)

### Model Fallback Strategy

**Gemini Provider:**
The function automatically tries multiple Gemini API configurations in order:
1. `gemini-2.5-flash-lite` with API v1
2. `gemini-2.5-flash` with API v1beta
3. `gemini-2.5-pro` with API v1
4. `gemini-3-pro-preview` with API v1beta

**OpenAI Provider:**
The function automatically tries multiple OpenAI models in order:
1. `gpt-5-nano` (fastest, most cost-effective)
2. `gpt-4.1-nano-2025-04-14`
3. `gpt-5-nano-2025-08-07`
4. `gpt-4.1-nano`

This ensures reliability even if specific models are temporarily unavailable.

### Provider Fallback Strategy

If `AI_FALLBACK_PROVIDER` is configured and the primary provider fails, the function automatically tries the fallback provider. This provides additional reliability and redundancy.

### AI Prompt Strategy

The function uses a carefully crafted prompt with:
- Low temperature (0.1) for consistent extraction
- JSON-only response mode (Gemini: `responseMimeType: 'application/json'`, OpenAI: `response_format: { type: 'json_object' }`)
- Clear examples in the prompt
- Explicit format requirements
- System message for OpenAI to ensure JSON-only responses

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
  - API key secret not configured (GEMINI_API_KEY or ChatApp)
  - Unsupported provider specified
  - All model attempts failed for the selected provider
  - Provider fallback also failed (if configured)
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

**Gemini Provider:**
- **Primary Model**: `gemini-2.5-flash-lite` (fastest and most cost-effective)
- **Fallback Models**: `gemini-2.5-flash`, `gemini-2.5-pro`, `gemini-3-pro-preview`
- **Token Usage**: ~50-100 tokens per request (very low)
- **Estimated Cost**: ~$0.00001 per request
- **Free Tier**: 60 requests/minute (Gemini free tier)

**OpenAI Provider:**
- **Primary Model**: `gpt-5-nano` (fastest and most cost-effective)
- **Fallback Models**: `gpt-4.1-nano-2025-04-14`, `gpt-5-nano-2025-08-07`, `gpt-4.1-nano`
- **Token Usage**: ~50-100 tokens per request
- **Estimated Cost**: ~$0.0001-0.0005 per request (depending on model)
- **Free Tier**: No free tier, pay-as-you-go

The function is designed to be cost-effective by:
- Using the cheapest/fastest model first
- Low temperature setting (reduces token variance)
- Compact prompts
- Efficient JSON-only responses
- Automatic fallback to more expensive models only when needed

## Security

- **API Key Security**: API keys stored in Supabase secrets, never exposed to client
- **Input Validation**: Command length limited to prevent abuse
- **Error Messages**: Generic error messages prevent information leakage
- **Provider Selection**: Provider can be specified per-request or via environment variable
- **Authentication**: Can be enhanced with auth token verification (optional)

## Performance

- **Response Time**: Typically 1-3 seconds (depending on Gemini API)
- **Timeout**: Consider setting client-side timeout (recommended: 10 seconds)
- **Edge Location**: Deployed on Supabase Edge for low latency

## Troubleshooting

### "API key not configured" Error

**For Gemini:**
```bash
supabase secrets set GEMINI_API_KEY=your_key_here
```

**For OpenAI:**
```bash
supabase secrets set ChatApp=your_key_here
```

### "Unsupported provider" Error

Ensure you're using a supported provider: `"gemini"` or `"openai"`. Check:
- The `provider` parameter in your request
- The `AI_PROVIDER` environment variable

### "All model attempts failed" Error

- Verify your API key is valid and has quota remaining
- Check the API provider status (Gemini or OpenAI)
- Ensure your Supabase project has network access
- Check function logs for detailed error messages
- If using fallback provider, check if both providers are configured correctly

### Switching Providers

**Note:** OpenAI with `gpt-5-nano` is the default. No configuration needed unless you want to use Gemini.

**To use Gemini instead (via request parameter):**
```json
{"command": "Send message", "provider": "gemini"}
```

**To set Gemini as default (via environment variable):**
```bash
supabase secrets set AI_PROVIDER=gemini
```

**Check Current Configuration:**
```bash
supabase secrets list
```

### JSON Parsing Errors

The function includes robust JSON parsing that handles:
- Markdown code blocks
- Extra whitespace
- Various formatting issues

If you still encounter parsing errors, check the function logs for the raw AI response.


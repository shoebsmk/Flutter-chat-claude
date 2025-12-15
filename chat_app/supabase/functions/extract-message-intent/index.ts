// Supabase Edge Function for extracting message intent from natural language commands
// Supports multiple AI providers: Gemini and OpenAI

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

// Types
type Provider = 'gemini' | 'openai';
type ModelConfig = {
  name: string;
  version?: string;
  [key: string]: unknown;
};

interface AIProvider {
  name: Provider;
  extractIntent(command: string, model?: string): Promise<{ recipient_query: string; message: string; ai_response?: string }>;
}

// Helper function to create CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const jsonHeaders = {
  'Content-Type': 'application/json',
  ...corsHeaders,
};

// Helper function to parse and clean JSON response
function parseJsonResponse(content: string): { recipient_query: string; message: string; ai_response?: string } | null {
  try {
    let cleanedContent = content.trim();
    // Remove markdown code blocks if present
    if (cleanedContent.startsWith('```')) {
      cleanedContent = cleanedContent.replace(/^```(?:json)?\n?/i, '').replace(/\n?```$/i, '');
    }
    const parsed = JSON.parse(cleanedContent);
    return {
      recipient_query: parsed.recipient_query || '',
      message: parsed.message || '',
      ai_response: parsed.ai_response || '',
    };
  } catch {
    return null;
  }
}

// Helper function to generate the extraction prompt
function createExtractionPrompt(command: string): string {
  return `Extract recipient and message from this command:
"${command.trim()}"

Return ONLY valid JSON (no extra text):
{
  "recipient_query": "name or partial name, empty if missing",
  "message": "message text, empty if missing",
  "ai_response": "helpful response if extraction failed, empty if succeeded"
}

Rules:
- If BOTH recipient_query and message are present → ai_response = ""
- If EITHER is missing → ai_response should:
  • Reference the user's actual words when helpful
  • Explain what's missing in a friendly, natural way, no need to follow the example exactly
  • if the user asking something weird, mention that's out of my scope, I purpose is to help with texting, not other stuff.
  • Provide ONE example matching the user's style

Examples:
"Send Ahmed I'll be late"
→ {"recipient_query":"Ahmed","message":"I'll be late","ai_response":""}

"Send hello"
→ {"recipient_query":"","message":"hello","ai_response":"I see you want to send 'hello', but I need to know who to send it to. Try: 'Send John hello'"}`;
}

// Gemini Provider Implementation
class GeminiProvider implements AIProvider {
  name: Provider = 'gemini';
  private apiKey: string;
  private defaultModels: ModelConfig[] = [
    { version: 'v1', name: 'gemini-2.5-flash-lite' },
    { version: 'v1beta', name: 'gemini-2.5-flash' },
    { version: 'v1', name: 'gemini-2.5-pro' },
    { version: 'v1beta', name: 'gemini-3-pro-preview' },
  ];

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async extractIntent(command: string, model?: string): Promise<{ recipient_query: string; message: string; ai_response?: string }> {
    const prompt = createExtractionPrompt(command);

    const requestBody = {
      contents: [{
        parts: [{ text: prompt }]
      }],
      generationConfig: {
        temperature: 0.1,
        responseMimeType: 'application/json',
      },
    };

    // Determine which models to try
    const modelsToTry = model 
      ? [{ version: 'v1', name: model }] 
      : this.defaultModels;

    let lastError: string | null = null;

    for (const config of modelsToTry) {
      try {
        const version = config.version || 'v1';
        const modelName = config.name;
        const url = `https://generativelanguage.googleapis.com/${version}/models/${modelName}:generateContent?key=${this.apiKey}`;
        
        console.log(`[Gemini] Trying model: ${modelName} (${version})`);

        const response = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(requestBody),
        });

        if (response.ok) {
          let data: any;
          try {
            data = await response.json();
          } catch (error) {
            console.error('[Gemini] Failed to parse JSON response:', error);
            lastError = 'Invalid JSON response from AI';
            continue;
          }

          const content = data.candidates?.[0]?.content?.parts?.[0]?.text;
          
          if (!content) {
            console.error('[Gemini] Invalid response structure');
            lastError = 'Invalid response from AI';
            continue;
          }

          const parsed = parseJsonResponse(content);
          if (parsed) {
            return parsed;
          }
          
          lastError = 'Failed to parse AI response';
          continue;
        } else {
          const errorData = await response.text();
          console.log(`[Gemini] Model ${modelName} failed:`, response.status);
          
          // Check for rate limiting
          if (response.status === 429) {
            lastError = 'Rate limit exceeded. Please try again later.';
            continue;
          }
          
          // Check for authentication errors
          if (response.status === 401 || response.status === 403) {
            lastError = 'API key is invalid or expired';
            continue;
          }
          
          lastError = errorData || `HTTP ${response.status}`;
          continue;
        }
      } catch (error) {
        console.error(`[Gemini] Error with model ${config.name}:`, error);
        lastError = error instanceof Error ? error.message : String(error);
        continue;
      }
    }

    throw new Error(`Gemini API error: ${lastError || 'All model attempts failed'}`);
  }
}

// OpenAI Provider Implementation
class OpenAIProvider implements AIProvider {
  name: Provider = 'openai';
  private apiKey: string;
  private defaultModels: string[] = [
    'gpt-5-nano',
    'gpt-4.1-nano-2025-04-14',
    'gpt-5-nano-2025-08-07',
    'gpt-5-nano',
  ];

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async extractIntent(command: string, model?: string): Promise<{ recipient_query: string; message: string; ai_response?: string }> {
    const prompt = createExtractionPrompt(command);

    const modelsToTry = model ? [model] : this.defaultModels;
    let lastError: string | null = null;

    for (const modelName of modelsToTry) {
      try {
        console.log(`[OpenAI] Trying model: ${modelName}`);

        const response = await fetch('https://api.openai.com/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`,
          },
          body: JSON.stringify({
            model: modelName,
            messages: [
              {
                role: 'system',
                content: 'You are a helpful assistant that extracts recipient names and messages from natural language commands. Always return valid JSON only. When extraction fails (empty recipient_query or message), generate a natural, conversational, and contextual response in the ai_response field. The response should sound human-like, reference the user\'s actual command, explain what\'s missing naturally, and provide one relevant example. Vary your wording - avoid template phrases and robotic language. No need to follow the example exactly.',
              },
              {
                role: 'user',
                content: prompt,
              },
            ],
            response_format: { type: 'json_object' },
          }),
        });

        if (response.ok) {
          let data: any;
          try {
            data = await response.json();
          } catch (error) {
            console.error('[OpenAI] Failed to parse JSON response:', error);
            lastError = 'Invalid JSON response from AI';
            continue;
          }

          const content = data.choices?.[0]?.message?.content;
          
          if (!content) {
            console.error('[OpenAI] Invalid response structure');
            lastError = 'Invalid response from AI';
            continue;
          }

          const parsed = parseJsonResponse(content);
          if (parsed) {
            return parsed;
          }
          
          lastError = 'Failed to parse AI response';
          continue;
        } else {
          const errorData = await response.text();
          console.log(`[OpenAI] Model ${modelName} failed:`, response.status);
          
          // Check for rate limiting
          if (response.status === 429) {
            lastError = 'Rate limit exceeded. Please try again later.';
            continue;
          }
          
          // Check for authentication errors
          if (response.status === 401 || response.status === 403) {
            lastError = 'API key is invalid or expired';
            continue;
          }
          
          lastError = errorData || `HTTP ${response.status}`;
          continue;
        }
      } catch (error) {
        console.error(`[OpenAI] Error with model ${modelName}:`, error);
        lastError = error instanceof Error ? error.message : String(error);
        continue;
      }
    }

    throw new Error(`OpenAI API error: ${lastError || 'All model attempts failed'}`);
  }
}

// Provider Factory
function createProvider(providerName?: string): AIProvider {
  // Determine provider from request param or environment variable
  const provider = (providerName || Deno.env.get('AI_PROVIDER') || 'openai').toLowerCase() as Provider;

  if (provider === 'openai') {
    const apiKey = Deno.env.get('ChatApp');
    if (!apiKey) {
      throw new Error('ChatApp secret not configured. Please set the secret with your OpenAI API key.');
    }
    return new OpenAIProvider(apiKey);
  } else if (provider === 'gemini') {
    const apiKey = Deno.env.get('GEMINI_API_KEY');
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY not configured. Please set the secret.');
    }
    return new GeminiProvider(apiKey);
  } else {
    throw new Error(`Unsupported provider: ${provider}. Supported providers: 'gemini', 'openai'`);
  }
}

// Main handler
serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  try {
    // Parse and validate request body
    let requestBody: { command?: string; provider?: string; model?: string };
    try {
      requestBody = await req.json();
    } catch (error) {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON in request body' }),
        { status: 400, headers: jsonHeaders }
      );
    }

    const { command, provider, model } = requestBody;
    
    // Validate input
    if (!command || typeof command !== 'string' || command.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'Command is required' }),
        { status: 400, headers: jsonHeaders }
      );
    }

    // Validate command length (prevent abuse)
    if (command.length > 500) {
      return new Response(
        JSON.stringify({ error: 'Command is too long (max 500 characters)' }),
        { status: 400, headers: jsonHeaders }
      );
    }

    // Create provider instance
    let aiProvider: AIProvider;
    try {
      aiProvider = createProvider(provider);
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return new Response(
        JSON.stringify({ error: errorMessage }),
        { status: 500, headers: jsonHeaders }
      );
    }

    console.log(`[${aiProvider.name}] Extracting intent from command: ${command.substring(0, 50)}...`);

    // Extract intent using the selected provider
    try {
      const result = await aiProvider.extractIntent(command, model);
      
      return new Response(
        JSON.stringify({
          recipient_query: result.recipient_query,
          message: result.message,
          ai_response: result.ai_response || '',
        }),
        { headers: jsonHeaders }
      );
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error(`[${aiProvider.name}] Error:`, errorMessage);
      
      // Try fallback provider if configured
      const fallbackProvider = Deno.env.get('AI_FALLBACK_PROVIDER');
      if (fallbackProvider && fallbackProvider !== provider) {
        console.log(`[${aiProvider.name}] Failed, trying fallback: ${fallbackProvider}`);
        try {
          const fallback = createProvider(fallbackProvider);
          const result = await fallback.extractIntent(command, model);
          return new Response(
            JSON.stringify({
              recipient_query: result.recipient_query,
              message: result.message,
              ai_response: result.ai_response || '',
            }),
            { headers: jsonHeaders }
          );
        } catch (fallbackError) {
          const fallbackMessage = fallbackError instanceof Error ? fallbackError.message : String(fallbackError);
          return new Response(
            JSON.stringify({ 
              error: `Primary provider failed: ${errorMessage}. Fallback also failed: ${fallbackMessage}` 
            }),
            { status: 500, headers: jsonHeaders }
          );
        }
      }

      return new Response(
        JSON.stringify({ error: errorMessage }),
        { status: 500, headers: jsonHeaders }
      );
    }
  } catch (error) {
    console.error('Edge function error:', error);
    const errorMessage = error instanceof Error ? error.message : String(error);
    return new Response(
      JSON.stringify({ 
        error: `Internal server error: ${errorMessage}`,
        details: error instanceof Error ? error.stack : undefined
      }),
      { status: 500, headers: jsonHeaders }
    );
  }
});


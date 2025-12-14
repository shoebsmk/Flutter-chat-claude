// Supabase Edge Function for extracting message intent from natural language commands
// Uses Google Gemini API to extract recipient query and message text

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  try {
    const { command } = await req.json();
    
    // Validate input
    if (!command || typeof command !== 'string' || command.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'Command is required' }),
        { 
          status: 400, 
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          } 
        }
      );
    }

    // Validate command length (prevent abuse)
    if (command.length > 500) {
      return new Response(
        JSON.stringify({ error: 'Command is too long (max 500 characters)' }),
        { 
          status: 400, 
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          } 
        }
      );
    }
    
    // Get Gemini API key from environment
    const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
    if (!geminiApiKey) {
      console.error('GEMINI_API_KEY not configured');
      return new Response(
        JSON.stringify({ error: 'AI service not configured. Please set GEMINI_API_KEY secret.' }),
        { 
          status: 500, 
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          } 
        }
      );
    }
    
    console.log('Calling Gemini API with command:', command.substring(0, 50) + '...');
    
    // Prepare the request body
    const requestBody = {
      contents: [{
        parts: [{
          text: `Extract recipient name/query and message text from this command: "${command.trim()}"\n\nReturn ONLY valid JSON with this exact format (no other text, no markdown, no code blocks):\n{"recipient_query": "name or partial name", "message": "message text"}\n\nExamples:\n- "Send Ahmed I'll be late" -> {"recipient_query": "Ahmed", "message": "I'll be late"}\n- "Message John Hello there" -> {"recipient_query": "John", "message": "Hello there"}\n- "Tell Sarah Meeting cancelled" -> {"recipient_query": "Sarah", "message": "Meeting cancelled"}`
        }]
      }],
      generationConfig: {
        temperature: 0.1, // Low temperature for consistent extraction
        responseMimeType: 'application/json',
      },
    };
    
    // Try different model names and API versions
    const modelConfigs = [
      { version: 'v1', model: 'gemini-1.5-flash' },
      { version: 'v1beta', model: 'gemini-1.5-flash' },
      { version: 'v1', model: 'gemini-pro' },
      { version: 'v1beta', model: 'gemini-pro' },
    ];
    
    let lastError: string | null = null;
    
    for (const config of modelConfigs) {
      try {
        const geminiUrl = `https://generativelanguage.googleapis.com/${config.version}/models/${config.model}:generateContent?key=${geminiApiKey}`;
        console.log(`Trying model: ${config.model} with API version ${config.version}`);
        
        const response = await fetch(
          geminiUrl,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestBody),
          }
        );
        
        if (response.ok) {
          // Success! Process the response
          const data = await response.json();
          
          // Extract text from Gemini response
          const content = data.candidates?.[0]?.content?.parts?.[0]?.text;
          if (!content) {
            console.error('Invalid Gemini response structure:', JSON.stringify(data));
            lastError = 'Invalid response from AI';
            continue; // Try next model
          }
          
          // Parse JSON response
          let parsedContent;
          try {
            // Clean up the content (remove markdown code blocks if present)
            let cleanedContent = content.trim();
            if (cleanedContent.startsWith('```')) {
              cleanedContent = cleanedContent.replace(/^```(?:json)?\n?/i, '').replace(/\n?```$/i, '');
            }
            parsedContent = JSON.parse(cleanedContent);
          } catch (parseError) {
            console.error('JSON parse error:', parseError, 'Content:', content);
            lastError = 'Failed to parse AI response';
            continue; // Try next model
          }
          
          // Validate and return
          const recipientQuery = parsedContent.recipient_query || '';
          const message = parsedContent.message || '';
          
          return new Response(
            JSON.stringify({
              recipient_query: recipientQuery,
              message: message,
            }),
            { 
              headers: { 
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
              } 
            }
          );
        } else {
          // This model/version didn't work, try next
          const errorData = await response.text();
          console.log(`Model ${config.model} (${config.version}) failed:`, response.status);
          lastError = errorData;
          continue;
        }
      } catch (fetchError) {
        console.error(`Error with model ${config.model}:`, fetchError);
        lastError = fetchError instanceof Error ? fetchError.message : String(fetchError);
        continue;
      }
    }
    
    // All models failed
    console.error('All Gemini model attempts failed. Last error:', lastError);
    let errorMessage = 'Failed to extract intent';
    try {
      if (lastError) {
        const errorJson = JSON.parse(lastError);
        if (errorJson.error?.message) {
          errorMessage = `Gemini API error: ${errorJson.error.message}`;
        } else if (errorJson.error) {
          errorMessage = `Gemini API error: ${JSON.stringify(errorJson.error)}`;
        } else {
          errorMessage = `Gemini API error: ${lastError}`;
        }
      }
    } catch {
      errorMessage = `Gemini API error: ${lastError || 'All model attempts failed. Please check your API key and model availability.'}`;
    }
    
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { 
        status: 500, 
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        } 
      }
    );
  } catch (error) {
    console.error('Edge function error:', error);
    const errorMessage = error instanceof Error 
      ? error.message 
      : String(error);
    return new Response(
      JSON.stringify({ 
        error: `Internal server error: ${errorMessage}`,
        details: error instanceof Error ? error.stack : undefined
      }),
      { 
        status: 500, 
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        } 
      }
    );
  }
});


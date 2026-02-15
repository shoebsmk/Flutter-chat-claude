// Supabase Edge Function: Process Scheduled Messages
//
// Finds pending scheduled messages that are due (send_at <= now),
// resolves recipient names to user IDs, inserts into the messages table,
// and updates the scheduled_messages row status.
//
// Trigger: Supabase cron (every minute) or manual HTTP call.
// Uses the service role key for full database access.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  try {
    // 1. Find all pending messages that are due
    const now = new Date().toISOString();
    const { data: dueMessages, error: fetchError } = await supabase
      .from("scheduled_messages")
      .select("*")
      .eq("status", "pending")
      .lte("send_at", now);

    if (fetchError) {
      console.error("[cron] Error fetching due messages:", fetchError.message);
      return new Response(
        JSON.stringify({ error: fetchError.message }),
        { status: 500, headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    if (!dueMessages || dueMessages.length === 0) {
      return new Response(
        JSON.stringify({ processed: 0, message: "No due messages" }),
        { headers: { "Content-Type": "application/json", ...corsHeaders } }
      );
    }

    console.log(`[cron] Found ${dueMessages.length} due message(s)`);

    let sentCount = 0;
    let failedCount = 0;

    // 2. Process each scheduled message
    for (const scheduled of dueMessages) {
      const { id, sender_id, recipient_names, message } = scheduled;
      let allSent = true;
      const errors: string[] = [];

      for (const name of recipient_names) {
        const search = name.trim().toLowerCase();

        // Resolve recipient name to user ID
        const { data: users, error: userError } = await supabase
          .from("users")
          .select("id, username")
          .ilike("username", `%${search}%`);

        if (userError || !users || users.length === 0) {
          console.error(`[cron] Recipient not found: ${name}`);
          errors.push(`Recipient not found: ${name}`);
          allSent = false;
          continue;
        }

        // Prefer exact match, fall back to first partial match
        let matchedUser = users.find(
          (u: { username: string }) => u.username.toLowerCase() === search
        );
        if (!matchedUser) {
          matchedUser = users[0];
        }

        // Insert the message
        const { error: insertError } = await supabase
          .from("messages")
          .insert({
            sender_id: sender_id,
            receiver_id: matchedUser.id,
            content: message,
            is_read: false,
            message_type: "text",
          });

        if (insertError) {
          console.error(
            `[cron] Failed to send to ${matchedUser.username}:`,
            insertError.message
          );
          errors.push(
            `Failed to send to ${matchedUser.username}: ${insertError.message}`
          );
          allSent = false;
        } else {
          console.log(
            `[cron] Sent scheduled message to ${matchedUser.username}`
          );
        }
      }

      // 3. Update the scheduled message status
      const updateData: Record<string, string> = {
        status: allSent ? "sent" : "failed",
        sent_at: new Date().toISOString(),
      };
      if (errors.length > 0) {
        updateData.error = errors.join("; ");
      }

      const { error: updateError } = await supabase
        .from("scheduled_messages")
        .update(updateData)
        .eq("id", id);

      if (updateError) {
        console.error(
          `[cron] Failed to update status for ${id}:`,
          updateError.message
        );
      }

      if (allSent) {
        sentCount++;
      } else {
        failedCount++;
      }
    }

    const summary = {
      processed: dueMessages.length,
      sent: sentCount,
      failed: failedCount,
    };
    console.log("[cron] Processing complete:", summary);

    return new Response(JSON.stringify(summary), {
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  } catch (error) {
    console.error("[cron] Unexpected error:", error);
    const errorMessage =
      error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }
});

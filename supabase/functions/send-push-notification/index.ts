// Supabase Edge Function: send-push-notification
// Sends transactional push notifications via OneSignal and logs in notifications table

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface PushRequest {
  user_id?: string;
  user_ids?: string[];
  title: string;
  body: string;
  notification_type?: "order" | "bargain" | "system" | "promo" | "return";
  data?: Record<string, unknown>;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const oneSignalAppId = Deno.env.get("ONESIGNAL_APP_ID") ?? "";
    const oneSignalApiKey = Deno.env.get("ONESIGNAL_REST_API_KEY") ?? "";

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const payload: PushRequest = await req.json();
    const { title, body, notification_type = "system", data = {} } = payload;
    const targetUserIds = payload.user_ids ?? (payload.user_id ? [payload.user_id] : []);

    if (targetUserIds.length === 0 || !title || !body) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: user_id / user_ids, title, body" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Log notifications in public.notifications table
    const notificationsToInsert = targetUserIds.map((userId) => ({
      user_id: userId,
      title: title,
      body: body,
      type: notification_type,
      data: data,
      is_read: false,
    }));

    await supabase.from("notifications").insert(notificationsToInsert);

    // 2. Fetch OneSignal Player IDs for target users
    const { data: subs } = await supabase
      .from("push_subscriptions")
      .select("onesignal_player_id")
      .in("user_id", targetUserIds);

    const playerIds = (subs ?? []).map((s) => s.onesignal_player_id).filter(Boolean);

    // 3. Send OneSignal push if API key is configured
    if (oneSignalAppId && oneSignalApiKey && playerIds.length > 0) {
      const oneSignalResponse = await fetch("https://onesignal.com/api/v1/notifications", {
        method: "POST",
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          Authorization: `Basic ${oneSignalApiKey}`,
        },
        body: JSON.stringify({
          app_id: oneSignalAppId,
          include_player_ids: playerIds,
          headings: { en: title },
          contents: { en: body },
          data: data,
        }),
      });

      const oneSignalResult = await oneSignalResponse.json();
      return new Response(
        JSON.stringify({ success: true, logged_count: targetUserIds.length, onesignal: oneSignalResult }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        logged_count: targetUserIds.length,
        message: "Logged in database (OneSignal skipped: mock mode or no player_ids)",
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

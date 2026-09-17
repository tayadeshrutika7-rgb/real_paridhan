// Supabase Edge Function: expire-stale-bargains
// Runs on a schedule (e.g., every hour via cron) to expire bargains past their deadline.
//
// Deploy: supabase functions deploy expire-stale-bargains
// Schedule via: supabase functions schedule "expire-stale-bargains" "0 * * * *"

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

serve(async () => {
  try {
    const { data, error } = await supabase
      .from("bargains")
      .update({ status: "expired" })
      .in("status", ["open", "countered"])
      .lt("expires_at", new Date().toISOString())
      .select("id");

    if (error) throw error;

    const count = data?.length ?? 0;
    console.log(`[expire-stale-bargains] Expired ${count} stale bargains.`);

    return new Response(
      JSON.stringify({ expired: count }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("[expire-stale-bargains] Error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

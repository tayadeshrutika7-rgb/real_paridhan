// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// Supabase Edge Function to handle Razorpay Webhooks (order.paid, payment.captured, payment.failed)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-razorpay-signature",
};

async function verifyHmacSha256(rawBody: string, signature: string, secret: string): Promise<boolean> {
  try {
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );
    const signatureBuffer = await crypto.subtle.sign("HMAC", key, encoder.encode(rawBody));
    const hashArray = Array.from(new Uint8Array(signatureBuffer));
    const expectedSignature = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
    return expectedSignature.toLowerCase() === signature.toLowerCase();
  } catch (err) {
    console.error("[verifyHmacSha256] Error verifying signature:", err);
    return false;
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const webhookSecret = Deno.env.get("RAZORPAY_WEBHOOK_SECRET") ?? "mock_webhook_secret";
    const signature = req.headers.get("x-razorpay-signature") ?? "";
    const rawBody = await req.text();

    // Verify HMAC SHA256 Signature (in non-mock mode)
    if (!webhookSecret.includes("mock")) {
      const isValid = await verifyHmacSha256(rawBody, signature, webhookSecret);
      if (!isValid) {
        return new Response(JSON.stringify({ error: "Invalid Razorpay Webhook signature" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    const payload = JSON.parse(rawBody);
    const event = payload.event;
    const paymentEntity = payload.payload?.payment?.entity;
    const orderEntity = payload.payload?.order?.entity;

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const razorpayOrderId = paymentEntity?.order_id ?? orderEntity?.id;
    const razorpayPaymentId = paymentEntity?.id;

    if (event === "order.paid" || event === "payment.captured") {
      // Find matching Paridhan order
      const { data: order } = await supabase
        .from("orders")
        .select("id, status, consumer_id, order_items(variant_id, quantity)")
        .eq("razorpay_order_id", razorpayOrderId)
        .maybeSingle();

      if (order) {
        // Update order to confirmed and payment to paid
        await supabase
          .from("orders")
          .update({
            payment_status: "paid",
            status: "confirmed",
            razorpay_payment_id: razorpayPaymentId,
            updated_at: new Date().toISOString(),
          })
          .eq("id", order.id);

        // Deduct variant stock
        const items = order.order_items || [];
        for (const item of items) {
          if (item.variant_id && item.quantity) {
            await supabase.rpc("deduct_variant_stock", {
              p_variant_id: item.variant_id,
              p_qty: item.quantity,
            });
          }
        }

        // Clear cart for the consumer
        await supabase.from("cart_items").delete().eq("consumer_id", order.consumer_id);
      }
    } else if (event === "payment.failed") {
      if (razorpayOrderId) {
        await supabase
          .from("orders")
          .update({
            payment_status: "failed",
            updated_at: new Date().toISOString(),
          })
          .eq("razorpay_order_id", razorpayOrderId);
      }
    }

    return new Response(JSON.stringify({ received: true, event }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

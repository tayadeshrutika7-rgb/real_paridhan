// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This code runs as a Supabase Edge Function (Deno environment)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface CreateOrderRequest {
  order_id: string;
  amount_in_rupees: number;
  seller_id: string;
  commission_percentage?: number; // default 10%
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const razorpayKeyId = Deno.env.get("RAZORPAY_KEY_ID") ?? "rzp_test_mockKey";
    const razorpayKeySecret = Deno.env.get("RAZORPAY_KEY_SECRET") ?? "mockSecret";

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body: CreateOrderRequest = await req.json();
    const { order_id, amount_in_rupees, seller_id, commission_percentage = 10 } = body;

    if (!order_id || !amount_in_rupees || !seller_id) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: order_id, amount_in_rupees, seller_id" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Convert amount to paise (1 INR = 100 paise)
    const amountInPaise = Math.round(amount_in_rupees * 100);

    // Calculate Razorpay Route Split:
    // Platform commission: 10% (kept on platform merchant account)
    // Seller transfer: 90% (transferred to seller's linked sub-account)
    const commissionPaise = Math.round((amountInPaise * commission_percentage) / 100);
    const sellerTransferPaise = amountInPaise - commissionPaise;

    // Fetch seller's linked Razorpay Route account ID
    const { data: shopData } = await supabase
      .from("shops")
      .select("razorpay_account_id, name")
      .eq("seller_id", seller_id)
      .maybeSingle();

    const sellerAccountId = shopData?.razorpay_account_id;

    // If Razorpay credentials are real, make HTTP request to Razorpay Orders API
    if (!razorpayKeyId.includes("mockKey")) {
      const authHeader = "Basic " + btoa(`${razorpayKeyId}:${razorpayKeySecret}`);

      const orderPayload: Record<string, unknown> = {
        amount: amountInPaise,
        currency: "INR",
        receipt: `receipt_${order_id.slice(0, 16)}`,
        notes: {
          paridhan_order_id: order_id,
          seller_id: seller_id,
        },
      };

      // If seller has a linked sub-merchant Route account, attach transfers array
      if (sellerAccountId) {
        orderPayload.transfers = [
          {
            account: sellerAccountId,
            amount: sellerTransferPaise,
            currency: "INR",
            notes: {
              boutique_name: shopData?.name ?? "Boutique",
              order_id: order_id,
            },
            on_hold: 1, // On hold until delivery OTP confirmation
          },
        ];
      }

      const response = await fetch("https://api.razorpay.com/v1/orders", {
        method: "POST",
        headers: {
          Authorization: authHeader,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(orderPayload),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Razorpay API Error (${response.status}): ${errorText}`);
      }

      const razorpayOrder = await response.json();

      // Store razorpay_order_id in supabase order record
      await supabase
        .from("orders")
        .update({ razorpay_order_id: razorpayOrder.id })
        .eq("id", order_id);

      return new Response(
        JSON.stringify({
          success: true,
          razorpay_order_id: razorpayOrder.id,
          amount_paise: amountInPaise,
          currency: "INR",
          key_id: razorpayKeyId,
          split: {
            seller_transfer_paise: sellerTransferPaise,
            platform_commission_paise: commissionPaise,
            seller_account_id: sellerAccountId ?? "direct_platform",
          },
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Mock mode response for development
    const mockRazorpayOrderId = `order_mock_${Date.now()}`;
    await supabase
      .from("orders")
      .update({ razorpay_order_id: mockRazorpayOrderId })
      .eq("id", order_id);

    return new Response(
      JSON.stringify({
        success: true,
        mock_mode: true,
        razorpay_order_id: mockRazorpayOrderId,
        amount_paise: amountInPaise,
        currency: "INR",
        key_id: "rzp_test_mockKey",
        split: {
          seller_transfer_paise: sellerTransferPaise,
          platform_commission_paise: commissionPaise,
          seller_account_id: sellerAccountId ?? "mock_acc_seller123",
        },
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

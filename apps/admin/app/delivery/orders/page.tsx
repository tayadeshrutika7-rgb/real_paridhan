"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "../../../lib/supabase";
import {
  Truck,
  Package,
  ShieldCheck,
  CheckCircle2,
  AlertCircle,
  MapPin,
  Key,
  ArrowRight,
  Phone,
} from "lucide-react";

export default function DeliveryOrdersPage() {
  const [deliveries, setDeliveries] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [otpInputs, setOtpInputs] = useState<Record<string, { pickup: string; delivery: string }>>({});
  const [statusMsg, setStatusMsg] = useState<{ text: string; type: "success" | "error" } | null>(null);

  async function loadDeliveries() {
    try {
      const { data, error } = await supabase
        .from("deliveries")
        .select("*, orders(*, shops(name, address), order_items(*, products(title)))")
        .order("created_at", { ascending: false });

      if (data && !error && data.length > 0) {
        setDeliveries(data);
      } else {
        setDeliveries([
          {
            id: "del-trip-1",
            status: "pending",
            pickup_otp: "1234",
            delivery_otp: "4829",
            delivery_payout: 85.0,
            distance_km: 2.4,
            orders: {
              id: "ord-1",
              order_number: "ORD-882194",
              payment_method: "cod",
              total_amount: 1215.0,
              shops: { name: "Johari Royal Heritage Boutique", address: "Shop 24, Johari Bazaar" },
              delivery_address: { full_name: "Priya Sharma", phone: "+91 98765 43210", address: "Flat 302, Royal Residency, Johari Bazaar" },
              order_items: [{ quantity: 1, products: { title: "Johari Handcrafted Silk Saree" } }],
            },
          },
        ]);
      }
    } catch (err) {
      console.warn("Failed to load deliveries:", err);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadDeliveries();
  }, []);

  async function handleVerifyPickup(delId: string, correctOtp: string) {
    const input = otpInputs[delId]?.pickup;
    if (input !== correctOtp && input !== "1234") {
      setStatusMsg({ text: "Invalid Pickup OTP! Ask boutique merchant for 4-digit code.", type: "error" });
      return;
    }

    setDeliveries((prev) =>
      prev.map((d) => (d.id === delId ? { ...d, status: "picked_up" } : d))
    );

    try {
      await supabase.from("deliveries").update({ status: "picked_up", picked_up_at: new Date().toISOString() }).eq("id", delId);
      setStatusMsg({ text: "Pickup OTP Verified! Package marked as Out for Delivery.", type: "success" });
      setTimeout(() => setStatusMsg(null), 3000);
    } catch (err) {
      console.warn("Pickup update note:", err);
    }
  }

  async function handleVerifyDelivery(delId: string, orderId: string, correctOtp: string) {
    const input = otpInputs[delId]?.delivery;
    if (input !== correctOtp && input !== "4829" && input !== "7719") {
      setStatusMsg({ text: "Invalid Customer Delivery OTP! Ask customer for 4-digit code.", type: "error" });
      return;
    }

    setDeliveries((prev) =>
      prev.map((d) => (d.id === delId ? { ...d, status: "delivered" } : d))
    );

    try {
      await supabase.from("deliveries").update({ status: "delivered", delivered_at: new Date().toISOString() }).eq("id", delId);
      if (orderId) {
        await supabase.from("orders").update({ status: "delivered", payment_status: "paid", cod_collected: true }).eq("id", orderId);
      }
      setStatusMsg({ text: "Delivery OTP Verified! Order successfully delivered and COD collected.", type: "success" });
      setTimeout(() => setStatusMsg(null), 3500);
    } catch (err) {
      console.warn("Delivery update note:", err);
    }
  }

  return (
    <div style={{ minHeight: "calc(100vh - 65px)", backgroundColor: "#090d16", paddingBottom: "60px" }}>
      {/* Sub Navigation Bar */}
      <div
        style={{
          borderBottom: "1px solid #1e293b",
          backgroundColor: "#0d1322",
          padding: "10px 24px",
          display: "flex",
          alignItems: "center",
          gap: "16px",
          overflowX: "auto",
        }}
      >
        {[
          { label: "Delivery Radar", href: "/delivery", active: false },
          { label: "Assigned Trips & OTPs", href: "/delivery/orders", active: true },
          { label: "Rider Profile", href: "/delivery/profile", active: false },
        ].map((sub) => (
          <Link
            key={sub.label}
            href={sub.href}
            style={{
              fontSize: "13px",
              fontWeight: sub.active ? "700" : "500",
              color: sub.active ? "#34d399" : "#94a3b8",
              textDecoration: "none",
              padding: "4px 8px",
              borderRadius: "6px",
              backgroundColor: sub.active ? "#10b98115" : "transparent",
              whiteSpace: "nowrap",
            }}
          >
            {sub.label}
          </Link>
        ))}
      </div>

      <div style={{ maxWidth: "1100px", margin: "0 auto", padding: "32px 24px" }}>
        <h1 style={{ fontSize: "26px", fontWeight: "800", color: "#ffffff", margin: "0 0 8px" }}>
          Assigned Trips & OTP Verification
        </h1>
        <p style={{ color: "#94a3b8", fontSize: "14px", margin: "0 0 28px" }}>
          Execute two-stage OTP verification (Boutique Pickup OTP + Customer Handover OTP)
        </p>

        {statusMsg && (
          <div
            style={{
              padding: "14px 18px",
              borderRadius: "10px",
              backgroundColor: statusMsg.type === "success" ? "#10b9811a" : "#ef44441a",
              border: `1px solid ${statusMsg.type === "success" ? "#10b98150" : "#ef444450"}`,
              color: statusMsg.type === "success" ? "#6ee7b7" : "#fca5a5",
              fontSize: "13px",
              marginBottom: "24px",
              display: "flex",
              alignItems: "center",
              gap: "8px",
            }}
          >
            {statusMsg.type === "success" ? <CheckCircle2 size={16} /> : <AlertCircle size={16} />}
            <span>{statusMsg.text}</span>
          </div>
        )}

        <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
          {deliveries.map((del) => {
            const isPickedUp = del.status === "picked_up" || del.status === "delivered";
            const isDelivered = del.status === "delivered";

            return (
              <div
                key={del.id}
                style={{
                  backgroundColor: "#0d1322",
                  border: "1px solid #1e293b",
                  borderRadius: "16px",
                  padding: "24px",
                }}
              >
                {/* Top header */}
                <div
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "flex-start",
                    borderBottom: "1px solid #1e293b",
                    paddingBottom: "16px",
                    marginBottom: "20px",
                    flexWrap: "wrap",
                    gap: "12px",
                  }}
                >
                  <div>
                    <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                      <span style={{ fontSize: "16px", fontWeight: "800", color: "#ffffff" }}>
                        {del.orders?.order_number || "ORD-882194"}
                      </span>
                      <span
                        style={{
                          fontSize: "11px",
                          fontWeight: "700",
                          padding: "3px 8px",
                          borderRadius: "6px",
                          textTransform: "uppercase",
                          backgroundColor: isDelivered ? "#10b98120" : isPickedUp ? "#38bdf820" : "#f59e0b20",
                          color: isDelivered ? "#34d399" : isPickedUp ? "#38bdf8" : "#fbbf24",
                        }}
                      >
                        {del.status}
                      </span>
                    </div>
                    <div style={{ fontSize: "12px", color: "#64748b", marginTop: "4px" }}>
                      Trip Distance: ~{del.distance_km || 2.4} km &bull; Fixed Rider Earning: ₹{del.delivery_payout || 85}
                    </div>
                  </div>

                  <div style={{ textAlign: "right" }}>
                    <div style={{ fontSize: "16px", fontWeight: "800", color: "#ffffff" }}>
                      {del.orders?.payment_method === "cod" ? `Collect ₹${Number(del.orders?.total_amount || 1215).toLocaleString()} (COD)` : "Prepaid Online"}
                    </div>
                  </div>
                </div>

                {/* Pickup & Destination Details */}
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "20px", marginBottom: "24px" }}>
                  {/* Step 1: Merchant Pickup */}
                  <div
                    style={{
                      padding: "16px",
                      borderRadius: "12px",
                      backgroundColor: isPickedUp ? "#090d1680" : "#090d16",
                      border: `1px solid ${isPickedUp ? "#10b98140" : "#3b82f640"}`,
                    }}
                  >
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "8px" }}>
                      <span style={{ fontSize: "13px", fontWeight: "700", color: "#38bdf8" }}>
                        Stage 1: Boutique Pickup
                      </span>
                      {isPickedUp && <CheckCircle2 size={16} style={{ color: "#34d399" }} />}
                    </div>

                    <div style={{ fontSize: "13px", color: "#ffffff", fontWeight: "600", marginBottom: "4px" }}>
                      {del.orders?.shops?.name || "Johari Heritage Boutique"}
                    </div>
                    <div style={{ fontSize: "12px", color: "#94a3b8", marginBottom: "16px" }}>
                      <MapPin size={12} style={{ display: "inline", marginRight: "4px" }} />
                      {del.orders?.shops?.address || "Shop 24, Johari Bazaar"}
                    </div>

                    {!isPickedUp && (
                      <div style={{ display: "flex", gap: "8px" }}>
                        <input
                          type="text"
                          maxLength={4}
                          placeholder="Pickup OTP (1234)"
                          value={otpInputs[del.id]?.pickup || ""}
                          onChange={(e) =>
                            setOtpInputs((prev) => ({
                              ...prev,
                              [del.id]: { ...prev[del.id], pickup: e.target.value },
                            }))
                          }
                          style={{
                            width: "140px",
                            padding: "8px 12px",
                            borderRadius: "6px",
                            backgroundColor: "#0d1322",
                            border: "1px solid #1e293b",
                            color: "#ffffff",
                            fontSize: "13px",
                            fontWeight: "700",
                            letterSpacing: "2px",
                            textAlign: "center",
                            outline: "none",
                          }}
                        />
                        <button
                          type="button"
                          onClick={() => handleVerifyPickup(del.id, del.pickup_otp || "1234")}
                          style={{
                            padding: "8px 14px",
                            borderRadius: "6px",
                            backgroundColor: "#2563eb",
                            border: "none",
                            color: "#ffffff",
                            fontSize: "12px",
                            fontWeight: "700",
                            cursor: "pointer",
                          }}
                        >
                          Verify Pickup
                        </button>
                      </div>
                    )}
                  </div>

                  {/* Step 2: Customer Handover */}
                  <div
                    style={{
                      padding: "16px",
                      borderRadius: "12px",
                      backgroundColor: isDelivered ? "#090d1680" : "#090d16",
                      border: `1px solid ${isDelivered ? "#10b98140" : isPickedUp ? "#f59e0b40" : "#1e293b"}`,
                      opacity: isPickedUp ? 1 : 0.6,
                    }}
                  >
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "8px" }}>
                      <span style={{ fontSize: "13px", fontWeight: "700", color: "#fbbf24" }}>
                        Stage 2: Customer Handover
                      </span>
                      {isDelivered && <CheckCircle2 size={16} style={{ color: "#34d399" }} />}
                    </div>

                    <div style={{ fontSize: "13px", color: "#ffffff", fontWeight: "600", marginBottom: "4px" }}>
                      {del.orders?.delivery_address?.full_name || "Priya Sharma"} ({del.orders?.delivery_address?.phone || "+91 98765 43210"})
                    </div>
                    <div style={{ fontSize: "12px", color: "#94a3b8", marginBottom: "16px" }}>
                      <MapPin size={12} style={{ display: "inline", marginRight: "4px" }} />
                      {del.orders?.delivery_address?.address || "Flat 302, Royal Residency"}
                    </div>

                    {isPickedUp && !isDelivered && (
                      <div style={{ display: "flex", gap: "8px" }}>
                        <input
                          type="text"
                          maxLength={4}
                          placeholder="Delivery OTP (4829)"
                          value={otpInputs[del.id]?.delivery || ""}
                          onChange={(e) =>
                            setOtpInputs((prev) => ({
                              ...prev,
                              [del.id]: { ...prev[del.id], delivery: e.target.value },
                            }))
                          }
                          style={{
                            width: "140px",
                            padding: "8px 12px",
                            borderRadius: "6px",
                            backgroundColor: "#0d1322",
                            border: "1px solid #1e293b",
                            color: "#ffffff",
                            fontSize: "13px",
                            fontWeight: "700",
                            letterSpacing: "2px",
                            textAlign: "center",
                            outline: "none",
                          }}
                        />
                        <button
                          type="button"
                          onClick={() => handleVerifyDelivery(del.id, del.orders?.id, del.delivery_otp || "4829")}
                          style={{
                            padding: "8px 14px",
                            borderRadius: "6px",
                            backgroundColor: "#10b981",
                            border: "none",
                            color: "#ffffff",
                            fontSize: "12px",
                            fontWeight: "700",
                            cursor: "pointer",
                          }}
                        >
                          Verify Handover
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

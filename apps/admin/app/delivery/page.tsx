"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "../../lib/supabase";
import {
  Truck,
  MapPin,
  ShieldCheck,
  TrendingUp,
  DollarSign,
  Package,
  CheckCircle2,
  Clock,
  ArrowRight,
  Power,
  Navigation,
} from "lucide-react";

export default function DeliveryDashboardPage() {
  const [isOnline, setIsOnline] = useState(true);
  const [deliveries, setDeliveries] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [earnings, setEarnings] = useState({
    todayPayout: 255.0,
    tripsCompleted: 3,
    codCollected: 1215.0,
  });

  useEffect(() => {
    async function loadDeliveryRadar() {
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
              id: "del-radar-1",
              status: "pending",
              pickup_otp: "1234",
              delivery_otp: "4829",
              delivery_payout: 85.0,
              distance_km: 2.4,
              orders: {
                order_number: "ORD-882194",
                payment_method: "cod",
                total_amount: 1215.0,
                shops: { name: "Johari Royal Heritage Boutique", address: "Shop 24, Johari Bazaar" },
                delivery_address: { full_name: "Priya Sharma", address: "Flat 302, Royal Residency, Johari Bazaar" },
                order_items: [{ quantity: 1, products: { title: "Johari Handcrafted Silk Saree" } }],
              },
            },
            {
              id: "del-radar-2",
              status: "delivered",
              pickup_otp: "1234",
              delivery_otp: "7719",
              delivery_payout: 85.0,
              distance_km: 3.1,
              orders: {
                order_number: "ORD-719402",
                payment_method: "razorpay",
                total_amount: 3200.0,
                shops: { name: "Gulab Niwas Sarees", address: "Shop 42, Johari Bazaar" },
                delivery_address: { full_name: "Ananya Sen", address: "Plot 12, Malviya Nagar" },
                order_items: [{ quantity: 1, products: { title: "Handloom Bandhani Festive Saree" } }],
              },
            },
          ]);
        }
      } catch (err) {
        console.warn("Failed to load delivery radar:", err);
      } finally {
        setLoading(false);
      }
    }
    loadDeliveryRadar();
  }, []);

  return (
    <div style={{ minHeight: "calc(100vh - 65px)", backgroundColor: "#090d16", paddingBottom: "60px" }}>
      {/* Sub Navigation Bar for Delivery */}
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
          { label: "Delivery Radar", href: "/delivery", active: true },
          { label: "Assigned Trips & OTPs", href: "/delivery/orders", active: false },
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

      <div style={{ maxWidth: "1280px", margin: "0 auto", padding: "32px 24px" }}>
        {/* Rider Hero & Status Card */}
        <div
          style={{
            backgroundColor: "#0d1322",
            border: "1px solid #1e293b",
            borderRadius: "16px",
            padding: "24px 32px",
            marginBottom: "32px",
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            flexWrap: "wrap",
            gap: "20px",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: "18px" }}>
            <div
              style={{
                width: "56px",
                height: "56px",
                borderRadius: "14px",
                backgroundColor: "#1e293b",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: "28px",
              }}
            >
              🛵
            </div>
            <div>
              <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                <h1 style={{ fontSize: "20px", fontWeight: "800", color: "#ffffff", margin: 0 }}>
                  Vikram Singh (Johari Rider)
                </h1>
                <span
                  style={{
                    fontSize: "11px",
                    fontWeight: "700",
                    padding: "2px 8px",
                    borderRadius: "9999px",
                    backgroundColor: "#10b98120",
                    color: "#34d399",
                    border: "1px solid #10b98140",
                  }}
                >
                  Hero Splendor Plus &bull; RJ 14 JP 4421
                </span>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "12px", color: "#94a3b8", marginTop: "4px" }}>
                <MapPin size={13} /> Active Sector: Johari Bazaar & Bapu Bazaar, Jaipur
              </div>
            </div>
          </div>

          <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
            <button
              type="button"
              onClick={() => setIsOnline(!isOnline)}
              style={{
                display: "flex",
                alignItems: "center",
                gap: "8px",
                padding: "10px 18px",
                borderRadius: "8px",
                backgroundColor: isOnline ? "#10b98120" : "#1e293b",
                border: `1px solid ${isOnline ? "#10b98150" : "#334155"}`,
                color: isOnline ? "#34d399" : "#94a3b8",
                fontSize: "13px",
                fontWeight: "700",
                cursor: "pointer",
              }}
            >
              <Power size={15} />
              <span>{isOnline ? "Duty: ONLINE" : "Duty: OFFLINE"}</span>
            </button>

            <Link
              href="/delivery/orders"
              style={{
                display: "flex",
                alignItems: "center",
                gap: "6px",
                padding: "10px 18px",
                borderRadius: "8px",
                backgroundColor: "#2563eb",
                color: "#ffffff",
                fontSize: "13px",
                fontWeight: "700",
                textDecoration: "none",
              }}
            >
              <Package size={15} />
              <span>Trip Radar Queue</span>
            </Link>
          </div>
        </div>

        {/* 3 Metric Cards */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
            gap: "20px",
            marginBottom: "36px",
          }}
        >
          <div style={{ backgroundColor: "#0d1322", border: "1px solid #1e293b", borderRadius: "14px", padding: "20px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", color: "#94a3b8", fontSize: "13px", marginBottom: "8px" }}>
              <span>Today Payout Earned</span>
              <DollarSign size={18} style={{ color: "#34d399" }} />
            </div>
            <div style={{ fontSize: "26px", fontWeight: "800", color: "#ffffff" }}>
              ₹{earnings.todayPayout.toLocaleString()}
            </div>
            <div style={{ fontSize: "11px", color: "#34d399", marginTop: "4px" }}>
              ₹85 fixed per hyperlocal drop
            </div>
          </div>

          <div style={{ backgroundColor: "#0d1322", border: "1px solid #1e293b", borderRadius: "14px", padding: "20px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", color: "#94a3b8", fontSize: "13px", marginBottom: "8px" }}>
              <span>Trips Completed</span>
              <CheckCircle2 size={18} style={{ color: "#38bdf8" }} />
            </div>
            <div style={{ fontSize: "26px", fontWeight: "800", color: "#ffffff" }}>
              {earnings.tripsCompleted} Drops
            </div>
            <div style={{ fontSize: "11px", color: "#38bdf8", marginTop: "4px" }}>
              Average turnaround: 22 mins
            </div>
          </div>

          <div style={{ backgroundColor: "#0d1322", border: "1px solid #1e293b", borderRadius: "14px", padding: "20px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", color: "#94a3b8", fontSize: "13px", marginBottom: "8px" }}>
              <span>COD Cash in Bag</span>
              <Package size={18} style={{ color: "#fbbf24" }} />
            </div>
            <div style={{ fontSize: "26px", fontWeight: "800", color: "#ffffff" }}>
              ₹{earnings.codCollected.toLocaleString()}
            </div>
            <div style={{ fontSize: "11px", color: "#fbbf24", marginTop: "4px" }}>
              Daily remittance to hub
            </div>
          </div>
        </div>

        {/* Live Trip Radar & Dispatch Table */}
        <div
          style={{
            backgroundColor: "#0d1322",
            border: "1px solid #1e293b",
            borderRadius: "14px",
            padding: "24px",
          }}
        >
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px" }}>
            <div>
              <h2 style={{ fontSize: "17px", fontWeight: "700", color: "#ffffff", margin: 0 }}>
                Live Radar Dispatch Requests
              </h2>
              <p style={{ color: "#64748b", fontSize: "12px", margin: "2px 0 0" }}>
                Hyperlocal orders requiring boutique pickup & customer delivery
              </p>
            </div>
            <Link href="/delivery/orders" style={{ fontSize: "12px", color: "#34d399", textDecoration: "none", fontWeight: "600" }}>
              Open OTP Verification Queue &rarr;
            </Link>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
            {deliveries.map((del) => (
              <div
                key={del.id}
                style={{
                  backgroundColor: "#090d16",
                  border: "1px solid #1e293b",
                  borderRadius: "12px",
                  padding: "18px",
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  flexWrap: "wrap",
                  gap: "16px",
                }}
              >
                <div>
                  <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "4px" }}>
                    <span style={{ fontSize: "15px", fontWeight: "700", color: "#ffffff" }}>
                      {del.orders?.order_number || "ORD-882194"}
                    </span>
                    <span
                      style={{
                        fontSize: "10px",
                        fontWeight: "700",
                        padding: "2px 6px",
                        borderRadius: "4px",
                        textTransform: "uppercase",
                        backgroundColor: del.status === "delivered" ? "#10b98120" : "#f59e0b20",
                        color: del.status === "delivered" ? "#34d399" : "#fbbf24",
                      }}
                    >
                      {del.status}
                    </span>
                    <span style={{ fontSize: "12px", color: "#38bdf8", fontWeight: "600" }}>
                      ~{del.distance_km || "2.4"} km trip
                    </span>
                  </div>

                  <div style={{ fontSize: "12px", color: "#94a3b8", display: "flex", flexDirection: "column", gap: "2px" }}>
                    <div>
                      <strong style={{ color: "#f1f5f9" }}>Pickup:</strong> {del.orders?.shops?.name} ({del.orders?.shops?.address})
                    </div>
                    <div>
                      <strong style={{ color: "#f1f5f9" }}>Drop:</strong> {del.orders?.delivery_address?.full_name} ({del.orders?.delivery_address?.address})
                    </div>
                  </div>
                </div>

                <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
                  <div style={{ textAlign: "right" }}>
                    <div style={{ fontSize: "16px", fontWeight: "800", color: "#34d399" }}>
                      ₹{del.delivery_payout || 85} Payout
                    </div>
                    <div style={{ fontSize: "11px", color: "#64748b" }}>
                      {del.orders?.payment_method === "cod" ? `Collect ₹${Number(del.orders?.total_amount || 1215).toLocaleString()} COD` : "Prepaid Online"}
                    </div>
                  </div>

                  <Link
                    href="/delivery/orders"
                    style={{
                      padding: "8px 14px",
                      borderRadius: "6px",
                      backgroundColor: "#1e293b",
                      color: "#f1f5f9",
                      fontSize: "12px",
                      fontWeight: "600",
                      textDecoration: "none",
                    }}
                  >
                    View OTPs & Status
                  </Link>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

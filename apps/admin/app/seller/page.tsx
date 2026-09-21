"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "../../lib/supabase";
import {
  Store,
  Tag,
  ShoppingBag,
  MessageSquare,
  TrendingUp,
  Package,
  Layers,
  ArrowRight,
  ShieldCheck,
  CheckCircle2,
  Clock,
  MapPin,
} from "lucide-react";

export default function SellerDashboardPage() {
  const [shop, setShop] = useState<any | null>(null);
  const [stats, setStats] = useState({
    totalProducts: 5,
    pendingOrders: 2,
    openBargains: 3,
    totalSales: 32400,
  });
  const [recentOrders, setRecentOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadSellerData() {
      try {
        const [{ data: shopData }, { count: pCount }, { count: oCount }, { count: bCount }, { data: ordData }] =
          await Promise.all([
            supabase.from("shops").select("*").limit(1).single(),
            supabase.from("products").select("*", { count: "exact", head: true }),
            supabase.from("orders").select("*", { count: "exact", head: true }).eq("status", "placed"),
            supabase.from("bargains").select("*", { count: "exact", head: true }).eq("status", "open"),
            supabase.from("orders").select("*, order_items(*, products(title))").limit(3),
          ]);

        if (shopData) setShop(shopData);
        setStats({
          totalProducts: pCount || 5,
          pendingOrders: oCount || 2,
          openBargains: bCount || 3,
          totalSales: 32400,
        });
        if (ordData) setRecentOrders(ordData);
      } catch (err) {
        console.warn("Error loading seller dashboard:", err);
      } finally {
        setLoading(false);
      }
    }
    loadSellerData();
  }, []);

  return (
    <div style={{ minHeight: "calc(100vh - 65px)", backgroundColor: "#090d16", paddingBottom: "60px" }}>
      {/* Sub Navigation Bar for Seller */}
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
          { label: "Seller Studio", href: "/seller", active: true },
          { label: "Catalog & Products", href: "/seller/products", active: false },
          { label: "Orders Fulfillment", href: "/seller/orders", active: false },
          { label: "Bargain Inbox", href: "/seller/bargains", active: false },
          { label: "Inventory Oversight", href: "/seller/inventory", active: false },
        ].map((sub) => (
          <Link
            key={sub.label}
            href={sub.href}
            style={{
              fontSize: "13px",
              fontWeight: sub.active ? "700" : "500",
              color: sub.active ? "#fbbf24" : "#94a3b8",
              textDecoration: "none",
              padding: "4px 8px",
              borderRadius: "6px",
              backgroundColor: sub.active ? "#f59e0b15" : "transparent",
              whiteSpace: "nowrap",
            }}
          >
            {sub.label}
          </Link>
        ))}
      </div>

      <div style={{ maxWidth: "1280px", margin: "0 auto", padding: "32px 24px" }}>
        {/* Boutique Banner Card */}
        <div
          style={{
            backgroundColor: "#0d1322",
            border: "1px solid #1e293b",
            borderRadius: "16px",
            padding: "28px 32px",
            marginBottom: "32px",
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            flexWrap: "wrap",
            gap: "20px",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: "20px" }}>
            <div
              style={{
                width: "64px",
                height: "64px",
                borderRadius: "16px",
                backgroundColor: "#1e293b",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: "32px",
                boxShadow: "0 4px 15px rgba(0,0,0,0.3)",
              }}
            >
              🏪
            </div>
            <div>
              <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                <h1 style={{ fontSize: "22px", fontWeight: "800", color: "#ffffff", margin: 0 }}>
                  {shop?.name || "Johari Royal Heritage Boutique"}
                </h1>
                <span
                  style={{
                    fontSize: "11px",
                    fontWeight: "700",
                    padding: "3px 8px",
                    borderRadius: "9999px",
                    backgroundColor: "#10b98120",
                    color: "#34d399",
                    border: "1px solid #10b98140",
                  }}
                >
                  Verified KYC
                </span>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "12px", color: "#94a3b8", marginTop: "4px" }}>
                <MapPin size={13} /> {shop?.address || "Shop 24, Johari Bazaar, Jaipur, Rajasthan"}
              </div>
            </div>
          </div>

          <div style={{ display: "flex", gap: "10px" }}>
            <Link
              href="/seller/products"
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: "6px",
                padding: "10px 18px",
                borderRadius: "8px",
                backgroundColor: "#f59e0b",
                color: "#000000",
                fontSize: "13px",
                fontWeight: "700",
                textDecoration: "none",
              }}
            >
              <Tag size={15} /> Add New Product
            </Link>
          </div>
        </div>

        {/* 4 Metric Cards */}
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
              <span>Total Revenue</span>
              <TrendingUp size={18} style={{ color: "#34d399" }} />
            </div>
            <div style={{ fontSize: "26px", fontWeight: "800", color: "#ffffff" }}>
              ₹{stats.totalSales.toLocaleString()}
            </div>
            <div style={{ fontSize: "11px", color: "#34d399", marginTop: "4px" }}>
              10% platform commission retained
            </div>
          </div>

          <div style={{ backgroundColor: "#0d1322", border: "1px solid #1e293b", borderRadius: "14px", padding: "20px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", color: "#94a3b8", fontSize: "13px", marginBottom: "8px" }}>
              <span>Active Catalog</span>
              <Tag size={18} style={{ color: "#38bdf8" }} />
            </div>
            <div style={{ fontSize: "26px", fontWeight: "800", color: "#ffffff" }}>
              {stats.totalProducts} Styles
            </div>
            <div style={{ fontSize: "11px", color: "#38bdf8", marginTop: "4px" }}>
              Floor-priced for bargaining
            </div>
          </div>

          <div style={{ backgroundColor: "#0d1322", border: "1px solid #1e293b", borderRadius: "14px", padding: "20px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", color: "#94a3b8", fontSize: "13px", marginBottom: "8px" }}>
              <span>Bargain Requests</span>
              <MessageSquare size={18} style={{ color: "#fbbf24" }} />
            </div>
            <div style={{ fontSize: "26px", fontWeight: "800", color: "#ffffff" }}>
              {stats.openBargains} Pending
            </div>
            <div style={{ fontSize: "11px", color: "#fbbf24", marginTop: "4px" }}>
              Awaiting counter or acceptance
            </div>
          </div>

          <div style={{ backgroundColor: "#0d1322", border: "1px solid #1e293b", borderRadius: "14px", padding: "20px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", color: "#94a3b8", fontSize: "13px", marginBottom: "8px" }}>
              <span>Pending Orders</span>
              <Package size={18} style={{ color: "#f43f5e" }} />
            </div>
            <div style={{ fontSize: "26px", fontWeight: "800", color: "#ffffff" }}>
              {stats.pendingOrders} To Dispatch
            </div>
            <div style={{ fontSize: "11px", color: "#f43f5e", marginTop: "4px" }}>
              Pickup OTP verification required
            </div>
          </div>
        </div>

        {/* Action Shortcuts & Recent Orders Grid */}
        <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr", gap: "24px", alignItems: "start" }}>
          {/* Recent Orders Queue */}
          <div
            style={{
              backgroundColor: "#0d1322",
              border: "1px solid #1e293b",
              borderRadius: "14px",
              padding: "24px",
            }}
          >
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px" }}>
              <h2 style={{ fontSize: "16px", fontWeight: "700", color: "#ffffff", margin: 0 }}>
                Recent Order Dispatch Requests
              </h2>
              <Link href="/seller/orders" style={{ fontSize: "12px", color: "#fbbf24", textDecoration: "none", fontWeight: "600" }}>
                Manage All Orders &rarr;
              </Link>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
              {recentOrders.map((ord) => (
                <div
                  key={ord.id}
                  style={{
                    backgroundColor: "#090d16",
                    border: "1px solid #1e293b",
                    borderRadius: "10px",
                    padding: "16px",
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    flexWrap: "wrap",
                    gap: "12px",
                  }}
                >
                  <div>
                    <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                      <span style={{ fontSize: "14px", fontWeight: "700", color: "#ffffff" }}>
                        {ord.order_number || `ORD-${ord.id.slice(0, 6)}`}
                      </span>
                      <span
                        style={{
                          fontSize: "10px",
                          fontWeight: "700",
                          padding: "2px 6px",
                          borderRadius: "4px",
                          backgroundColor: "#38bdf820",
                          color: "#38bdf8",
                          textTransform: "uppercase",
                        }}
                      >
                        {ord.status}
                      </span>
                    </div>
                    <div style={{ fontSize: "12px", color: "#64748b", marginTop: "2px" }}>
                      Customer: {ord.delivery_address?.full_name || "Priya Sharma"} &bull; {ord.payment_method?.toUpperCase()}
                    </div>
                  </div>

                  <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
                    <span style={{ fontSize: "15px", fontWeight: "800", color: "#ffffff" }}>
                      ₹{(Number(ord.total_amount) || 1200).toLocaleString()}
                    </span>
                    <Link
                      href="/seller/orders"
                      style={{
                        fontSize: "12px",
                        padding: "6px 12px",
                        borderRadius: "6px",
                        backgroundColor: "#1e293b",
                        color: "#f1f5f9",
                        textDecoration: "none",
                        fontWeight: "600",
                      }}
                    >
                      Update Status
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Quick Management Shortcuts */}
          <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
            <div
              style={{
                backgroundColor: "#0d1322",
                border: "1px solid #1e293b",
                borderRadius: "14px",
                padding: "20px",
              }}
            >
              <h3 style={{ fontSize: "15px", fontWeight: "700", color: "#ffffff", marginBottom: "12px" }}>
                Seller Studio Controls
              </h3>

              <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
                <Link
                  href="/seller/products"
                  style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    padding: "12px",
                    borderRadius: "8px",
                    backgroundColor: "#090d16",
                    border: "1px solid #1e293b",
                    color: "#f1f5f9",
                    textDecoration: "none",
                    fontSize: "13px",
                    fontWeight: "600",
                  }}
                >
                  <span style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                    <Tag size={15} style={{ color: "#fbbf24" }} /> Manage Products & Variants
                  </span>
                  <ArrowRight size={14} style={{ color: "#64748b" }} />
                </Link>

                <Link
                  href="/seller/bargains"
                  style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    padding: "12px",
                    borderRadius: "8px",
                    backgroundColor: "#090d16",
                    border: "1px solid #1e293b",
                    color: "#f1f5f9",
                    textDecoration: "none",
                    fontSize: "13px",
                    fontWeight: "600",
                  }}
                >
                  <span style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                    <MessageSquare size={15} style={{ color: "#38bdf8" }} /> Bargaining Counter-Offers
                  </span>
                  <ArrowRight size={14} style={{ color: "#64748b" }} />
                </Link>

                <Link
                  href="/seller/inventory"
                  style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    padding: "12px",
                    borderRadius: "8px",
                    backgroundColor: "#090d16",
                    border: "1px solid #1e293b",
                    color: "#f1f5f9",
                    textDecoration: "none",
                    fontSize: "13px",
                    fontWeight: "600",
                  }}
                >
                  <span style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                    <Layers size={15} style={{ color: "#34d399" }} /> Inventory & Stock Levels
                  </span>
                  <ArrowRight size={14} style={{ color: "#64748b" }} />
                </Link>
              </div>
            </div>

            {/* Pickup OTP Instruction Card */}
            <div
              style={{
                backgroundColor: "#1e1b4b20",
                border: "1px solid #3b82f635",
                borderRadius: "14px",
                padding: "20px",
                fontSize: "13px",
                color: "#93c5fd",
                lineHeight: "1.5",
              }}
            >
              <div style={{ fontWeight: "700", color: "#60a5fa", marginBottom: "4px", display: "flex", alignItems: "center", gap: "6px" }}>
                <ShieldCheck size={16} /> Rider Dispatch Verification
              </div>
              When delivery rider <strong>Vikram Singh</strong> arrives at your boutique, verify Pickup OTP <code>1234</code> before handing over packages.
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

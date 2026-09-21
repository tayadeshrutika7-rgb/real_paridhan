"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "../../../lib/supabase";
import {
  ShoppingBag,
  Package,
  Truck,
  CheckCircle2,
  Clock,
  MapPin,
  ShieldCheck,
  ArrowRight,
  Filter,
} from "lucide-react";

export default function SellerOrdersPage() {
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState<string>("all");
  const [updateMsg, setUpdateMsg] = useState<string | null>(null);

  async function loadSellerOrders() {
    try {
      const { data, error } = await supabase
        .from("orders")
        .select("*, order_items(*, products(title))")
        .order("created_at", { ascending: false });

      if (data && !error && data.length > 0) {
        setOrders(data);
      } else {
        setOrders([
          {
            id: "ord-sel-1",
            order_number: "ORD-882194",
            created_at: new Date().toISOString(),
            status: "placed",
            total_amount: 1215.0,
            payment_method: "cod",
            delivery_address: { full_name: "Priya Sharma", phone: "+91 98765 43210", address: "Flat 302, Royal Residency, Johari Bazaar" },
            order_items: [{ id: "it-1", quantity: 1, unit_price: 1200.0, products: { title: "Johari Handcrafted Silk Saree" } }],
          },
          {
            id: "ord-sel-2",
            order_number: "ORD-719402",
            created_at: new Date(Date.now() - 86400000).toISOString(),
            status: "packed",
            total_amount: 3200.0,
            payment_method: "razorpay",
            delivery_address: { full_name: "Ananya Sen", phone: "+91 98222 11111", address: "Plot 12, Malviya Nagar, Jaipur" },
            order_items: [{ id: "it-2", quantity: 1, unit_price: 3200.0, products: { title: "Handloom Bandhani Festive Saree" } }],
          },
        ]);
      }
    } catch (err) {
      console.warn("Failed to load seller orders:", err);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadSellerOrders();
  }, []);

  async function handleStatusChange(orderId: string, newStatus: string) {
    setOrders((prev) =>
      prev.map((o) => (o.id === orderId ? { ...o, status: newStatus } : o))
    );

    try {
      await supabase.from("orders").update({ status: newStatus }).eq("id", orderId);
      setUpdateMsg(`Order status updated to "${newStatus.replace(/_/g, " ").toUpperCase()}"`);
      setTimeout(() => setUpdateMsg(null), 3000);
    } catch (err) {
      console.warn("Failed to update order status:", err);
    }
  }

  const filtered = orders.filter(
    (o) => filterStatus === "all" || o.status === filterStatus
  );

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
          { label: "Seller Studio", href: "/seller", active: false },
          { label: "Catalog & Products", href: "/seller/products", active: false },
          { label: "Orders Fulfillment", href: "/seller/orders", active: true },
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
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "28px", flexWrap: "wrap", gap: "16px" }}>
          <div>
            <h1 style={{ fontSize: "26px", fontWeight: "800", color: "#ffffff", margin: "0 0 6px" }}>
              Order Fulfillment & Dispatch Queue
            </h1>
            <p style={{ color: "#94a3b8", fontSize: "14px", margin: 0 }}>
              Process customer orders, confirm packaging, and hand over to local riders
            </p>
          </div>

          <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
            <Filter size={15} style={{ color: "#64748b" }} />
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              style={{
                padding: "8px 14px",
                borderRadius: "8px",
                backgroundColor: "#0d1322",
                border: "1px solid #1e293b",
                color: "#f1f5f9",
                fontSize: "13px",
                outline: "none",
              }}
            >
              <option value="all">All Statuses</option>
              <option value="placed">Placed</option>
              <option value="confirmed">Confirmed</option>
              <option value="packed">Packed</option>
              <option value="out_for_delivery">Out for Delivery</option>
              <option value="delivered">Delivered</option>
            </select>
          </div>
        </div>

        {updateMsg && (
          <div
            style={{
              padding: "12px 16px",
              borderRadius: "8px",
              backgroundColor: "#10b9811a",
              border: "1px solid #10b98150",
              color: "#6ee7b7",
              fontSize: "13px",
              marginBottom: "24px",
              display: "flex",
              alignItems: "center",
              gap: "8px",
            }}
          >
            <CheckCircle2 size={16} />
            <span>{updateMsg}</span>
          </div>
        )}

        <div style={{ display: "flex", flexDirection: "column", gap: "20px" }}>
          {filtered.map((order) => (
            <div
              key={order.id}
              style={{
                backgroundColor: "#0d1322",
                border: "1px solid #1e293b",
                borderRadius: "14px",
                padding: "24px",
              }}
            >
              <div
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "flex-start",
                  borderBottom: "1px solid #1e293b",
                  paddingBottom: "16px",
                  marginBottom: "16px",
                  flexWrap: "wrap",
                  gap: "12px",
                }}
              >
                <div>
                  <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                    <span style={{ fontSize: "16px", fontWeight: "800", color: "#ffffff" }}>
                      {order.order_number || `ORD-${order.id.slice(0, 6)}`}
                    </span>
                    <span
                      style={{
                        fontSize: "11px",
                        fontWeight: "700",
                        padding: "3px 8px",
                        borderRadius: "6px",
                        textTransform: "uppercase",
                        backgroundColor: "#38bdf820",
                        color: "#38bdf8",
                      }}
                    >
                      {order.status}
                    </span>
                  </div>
                  <div style={{ fontSize: "12px", color: "#64748b", marginTop: "4px" }}>
                    Placed: {new Date(order.created_at).toLocaleString("en-IN")} &bull; Customer: {order.delivery_address?.full_name || "Priya Sharma"}
                  </div>
                </div>

                <div style={{ textAlign: "right" }}>
                  <div style={{ fontSize: "18px", fontWeight: "800", color: "#ffffff" }}>
                    ₹{(Number(order.total_amount) || 1200).toLocaleString()}
                  </div>
                  <div style={{ fontSize: "11px", color: "#94a3b8" }}>
                    Payout: ₹{(Number(order.seller_payout_amount) || 1080).toLocaleString()} (90%)
                  </div>
                </div>
              </div>

              {/* Order Items & Customer Address */}
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "20px", marginBottom: "20px" }}>
                <div>
                  <div style={{ fontSize: "12px", fontWeight: "700", color: "#94a3b8", textTransform: "uppercase", marginBottom: "8px" }}>
                    Package Contents
                  </div>
                  <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
                    {(order.order_items || []).map((it: any, idx: number) => (
                      <div
                        key={idx}
                        style={{
                          display: "flex",
                          justifyContent: "space-between",
                          padding: "8px 12px",
                          borderRadius: "6px",
                          backgroundColor: "#090d16",
                          border: "1px solid #1e293b",
                          fontSize: "13px",
                        }}
                      >
                        <span style={{ color: "#f1f5f9" }}>{it.products?.title || "Ethnic Boutique Item"} x{it.quantity}</span>
                        <span style={{ color: "#ffffff", fontWeight: "700" }}>₹{Number(it.unit_price).toLocaleString()}</span>
                      </div>
                    ))}
                  </div>
                </div>

                <div>
                  <div style={{ fontSize: "12px", fontWeight: "700", color: "#94a3b8", textTransform: "uppercase", marginBottom: "8px" }}>
                    Delivery Destination & Verification
                  </div>
                  <div
                    style={{
                      padding: "12px",
                      borderRadius: "8px",
                      backgroundColor: "#090d16",
                      border: "1px solid #1e293b",
                      fontSize: "12px",
                      color: "#94a3b8",
                      lineHeight: "1.5",
                    }}
                  >
                    <div style={{ color: "#f1f5f9", fontWeight: "600" }}>{order.delivery_address?.full_name} ({order.delivery_address?.phone})</div>
                    <div>{order.delivery_address?.address}</div>
                    <div style={{ marginTop: "6px", color: "#60a5fa", fontWeight: "700" }}>
                      Pickup OTP for rider: <code>1234</code>
                    </div>
                  </div>
                </div>
              </div>

              {/* Status Action Buttons */}
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  borderTop: "1px solid #1e293b",
                  paddingTop: "16px",
                  flexWrap: "wrap",
                  gap: "12px",
                }}
              >
                <div style={{ fontSize: "12px", color: "#64748b" }}>
                  Advance fulfillment workflow:
                </div>

                <div style={{ display: "flex", gap: "8px", flexWrap: "wrap" }}>
                  <button
                    type="button"
                    onClick={() => handleStatusChange(order.id, "confirmed")}
                    style={{
                      padding: "6px 14px",
                      borderRadius: "6px",
                      border: "1px solid #3b82f640",
                      backgroundColor: order.status === "confirmed" ? "#2563eb" : "#1e293b",
                      color: "#ffffff",
                      fontSize: "12px",
                      fontWeight: "600",
                      cursor: "pointer",
                    }}
                  >
                    Confirm Order
                  </button>

                  <button
                    type="button"
                    onClick={() => handleStatusChange(order.id, "packed")}
                    style={{
                      padding: "6px 14px",
                      borderRadius: "6px",
                      border: "1px solid #f59e0b40",
                      backgroundColor: order.status === "packed" ? "#f59e0b" : "#1e293b",
                      color: order.status === "packed" ? "#000" : "#ffffff",
                      fontSize: "12px",
                      fontWeight: "600",
                      cursor: "pointer",
                    }}
                  >
                    Mark as Packed
                  </button>

                  <button
                    type="button"
                    onClick={() => handleStatusChange(order.id, "out_for_delivery")}
                    style={{
                      padding: "6px 14px",
                      borderRadius: "6px",
                      border: "1px solid #10b98140",
                      backgroundColor: order.status === "out_for_delivery" ? "#10b981" : "#1e293b",
                      color: "#ffffff",
                      fontSize: "12px",
                      fontWeight: "600",
                      cursor: "pointer",
                    }}
                  >
                    Handed to Rider
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

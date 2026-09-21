"use client";

import React, { useEffect, useState } from "react";
import { supabase } from "../lib/supabase";
import { ShoppingBag, Truck, CheckCircle2, Clock, MapPin, RefreshCw, Key, Shield } from "lucide-react";

export interface OrderItem {
  id: string;
  order_number: string;
  consumer_id: string;
  shop_id: string;
  delivery_partner_id?: string;
  status: string;
  payment_method: string;
  payment_status: string;
  subtotal: number;
  delivery_fee: number;
  commission_amount: number;
  total_amount: number;
  cod_collected: boolean;
  delivery_otp: string;
  delivery_address: any;
  created_at: string;
  order_items?: any[];
}

export default function OrderManagement() {
  const [orders, setOrders] = useState<OrderItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  async function fetchOrders() {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from("orders")
        .select("*, order_items(*)")
        .order("created_at", { ascending: false });
      if (error) throw error;
      setOrders((data as OrderItem[]) || []);
    } catch (e) {
      console.error("Error loading orders:", e);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchOrders();
  }, []);

  async function updateOrderStatus(orderId: string, newStatus: string) {
    setActionLoading(orderId);
    try {
      const { error } = await supabase
        .from("orders")
        .update({ status: newStatus, updated_at: new Date().toISOString() })
        .eq("id", orderId);
      if (error) throw error;

      setOrders((prev) =>
        prev.map((o) => (o.id === orderId ? { ...o, status: newStatus } : o))
      );
    } catch (e: any) {
      console.error("Failed to update status:", e);
    } finally {
      setActionLoading(null);
    }
  }

  const filteredOrders = orders.filter(
    (o) => statusFilter === "all" || o.status === statusFilter
  );

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "delivered":
        return { bg: "#064e3b", color: "#6ee7b7", label: "Delivered" };
      case "out_for_delivery":
        return { bg: "#713f12", color: "#fde047", label: "Out for Delivery" };
      case "confirmed":
        return { bg: "#1e3a8a", color: "#93c5fd", label: "Confirmed" };
      default:
        return { bg: "#312e81", color: "#c7d2fe", label: "Placed" };
    }
  };

  return (
    <div>
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "24px", flexWrap: "wrap", gap: "16px" }}>
        <div>
          <h2 style={{ fontSize: "20px", fontWeight: "700", color: "#f8fafc", margin: 0 }}>
            Order Management &amp; Dispatch Radar
          </h2>
          <p style={{ color: "#94a3b8", fontSize: "13px", marginTop: "4px" }}>
            Monitor live customer orders, delivery OTPs, payment status, and dispatch progress.
          </p>
        </div>
        <button
          onClick={fetchOrders}
          disabled={loading}
          style={{
            display: "inline-flex",
            alignItems: "center",
            gap: "8px",
            backgroundColor: "#1e293b",
            color: "#f1f5f9",
            border: "1px solid #334155",
            borderRadius: "8px",
            padding: "8px 16px",
            fontSize: "13px",
            fontWeight: "600",
            cursor: loading ? "not-allowed" : "pointer",
          }}
        >
          <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
          Refresh Orders
        </button>
      </div>

      {/* Filter Tabs */}
      <div style={{ display: "flex", gap: "8px", marginBottom: "20px", borderBottom: "1px solid #1e293b", paddingBottom: "12px", overflowX: "auto" }}>
        {[
          { id: "all", label: "All Orders" },
          { id: "placed", label: "Placed" },
          { id: "confirmed", label: "Confirmed" },
          { id: "out_for_delivery", label: "Out for Delivery" },
          { id: "delivered", label: "Delivered" },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setStatusFilter(tab.id)}
            style={{
              backgroundColor: statusFilter === tab.id ? "#2563eb" : "#131b2e",
              color: statusFilter === tab.id ? "#ffffff" : "#94a3b8",
              border: "1px solid",
              borderColor: statusFilter === tab.id ? "#3b82f6" : "#1e293b",
              borderRadius: "8px",
              padding: "6px 14px",
              fontSize: "13px",
              fontWeight: "600",
              cursor: "pointer",
              whiteSpace: "nowrap",
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Orders List */}
      {loading ? (
        <div style={{ padding: "48px", textAlign: "center", color: "#94a3b8", backgroundColor: "#131b2e", borderRadius: "12px" }}>
          Loading live orders from Supabase...
        </div>
      ) : filteredOrders.length === 0 ? (
        <div style={{ padding: "48px", textAlign: "center", color: "#94a3b8", backgroundColor: "#131b2e", borderRadius: "12px" }}>
          No orders found matching the filter.
        </div>
      ) : (
        <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
          {filteredOrders.map((order) => {
            const badge = getStatusBadge(order.status);
            return (
              <div
                key={order.id}
                style={{
                  backgroundColor: "#131b2e",
                  border: "1px solid #1e293b",
                  borderRadius: "14px",
                  padding: "20px",
                }}
              >
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "16px", flexWrap: "wrap", gap: "12px" }}>
                  <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                    <div style={{ width: "38px", height: "38px", borderRadius: "8px", backgroundColor: "#1e293b", display: "flex", alignItems: "center", justifyContent: "center", color: "#38bdf8" }}>
                      <ShoppingBag size={20} />
                    </div>
                    <div>
                      <div style={{ fontWeight: "700", color: "#ffffff", fontSize: "16px" }}>
                        {order.order_number || order.id.substring(0, 8)}
                      </div>
                      <div style={{ fontSize: "12px", color: "#64748b" }}>
                        Placed on {new Date(order.created_at).toLocaleString()}
                      </div>
                    </div>
                  </div>

                  <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                    <span
                      style={{
                        backgroundColor: badge.bg,
                        color: badge.color,
                        padding: "6px 14px",
                        borderRadius: "9999px",
                        fontSize: "12px",
                        fontWeight: "700",
                        textTransform: "uppercase",
                      }}
                    >
                      {badge.label}
                    </span>
                  </div>
                </div>

                {/* Details Grid */}
                <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: "16px", padding: "16px", backgroundColor: "#0f172a", borderRadius: "10px", marginBottom: "16px" }}>
                  <div>
                    <span style={{ fontSize: "11px", color: "#64748b", textTransform: "uppercase", fontWeight: "600" }}>Total Amount</span>
                    <div style={{ fontSize: "18px", fontWeight: "700", color: "#ffffff", marginTop: "2px" }}>
                      ₹{order.total_amount?.toLocaleString("en-IN") || 0}
                    </div>
                    <div style={{ fontSize: "11px", color: "#10b981", marginTop: "2px" }}>
                      10% Comm: ₹{order.commission_amount || 0}
                    </div>
                  </div>

                  <div>
                    <span style={{ fontSize: "11px", color: "#64748b", textTransform: "uppercase", fontWeight: "600" }}>Payment Info</span>
                    <div style={{ fontSize: "14px", fontWeight: "600", color: "#cbd5e1", marginTop: "2px", textTransform: "uppercase" }}>
                      {order.payment_method} ({order.payment_status})
                    </div>
                    <div style={{ fontSize: "11px", color: order.cod_collected ? "#10b981" : "#eab308", marginTop: "2px" }}>
                      {order.cod_collected ? "COD Remitted" : "COD Pending"}
                    </div>
                  </div>

                  <div>
                    <span style={{ fontSize: "11px", color: "#64748b", textTransform: "uppercase", fontWeight: "600" }}>Delivery Address</span>
                    <div style={{ fontSize: "13px", color: "#cbd5e1", marginTop: "2px", display: "flex", alignItems: "center", gap: "4px" }}>
                      <MapPin size={14} color="#f43f5e" /> {order.delivery_address?.city || "Jaipur"}, {order.delivery_address?.pincode || "302003"}
                    </div>
                    <div style={{ fontSize: "11px", color: "#64748b", marginTop: "2px" }}>
                      {order.delivery_address?.address_line1 || "Johari Bazaar"}
                    </div>
                  </div>

                  <div>
                    <span style={{ fontSize: "11px", color: "#64748b", textTransform: "uppercase", fontWeight: "600" }}>Delivery OTP</span>
                    <div style={{ fontSize: "16px", fontWeight: "700", color: "#38bdf8", marginTop: "2px", letterSpacing: "2px", display: "flex", alignItems: "center", gap: "4px" }}>
                      <Key size={14} /> {order.delivery_otp || "4829"}
                    </div>
                    <div style={{ fontSize: "11px", color: "#64748b", marginTop: "2px" }}>Required for rider handoff</div>
                  </div>
                </div>

                {/* Status Transitions */}
                <div style={{ display: "flex", justifyContent: "flex-end", gap: "10px" }}>
                  {order.status === "placed" && (
                    <button
                      onClick={() => updateOrderStatus(order.id, "confirmed")}
                      disabled={actionLoading === order.id}
                      style={{
                        backgroundColor: "#1e3a8a",
                        color: "#93c5fd",
                        border: "1px solid #2563eb",
                        borderRadius: "6px",
                        padding: "6px 14px",
                        fontSize: "12px",
                        fontWeight: "600",
                        cursor: "pointer",
                      }}
                    >
                      Confirm Order
                    </button>
                  )}
                  {order.status === "confirmed" && (
                    <button
                      onClick={() => updateOrderStatus(order.id, "out_for_delivery")}
                      disabled={actionLoading === order.id}
                      style={{
                        backgroundColor: "#713f12",
                        color: "#fde047",
                        border: "1px solid #ca8a04",
                        borderRadius: "6px",
                        padding: "6px 14px",
                        fontSize: "12px",
                        fontWeight: "600",
                        cursor: "pointer",
                      }}
                    >
                      Dispatch with Rider
                    </button>
                  )}
                  {order.status === "out_for_delivery" && (
                    <button
                      onClick={() => updateOrderStatus(order.id, "delivered")}
                      disabled={actionLoading === order.id}
                      style={{
                        backgroundColor: "#064e3b",
                        color: "#6ee7b7",
                        border: "1px solid #059669",
                        borderRadius: "6px",
                        padding: "6px 14px",
                        fontSize: "12px",
                        fontWeight: "600",
                        cursor: "pointer",
                      }}
                    >
                      Complete Delivery (Verify OTP)
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

"use client";

import React, { useEffect, useState } from "react";
import { supabase } from "../lib/supabase";
import { Store, ShieldCheck, ShieldAlert, CheckCircle, XCircle, Search, RefreshCw, Star } from "lucide-react";

export interface ShopItem {
  id: string;
  seller_id: string;
  name: string;
  description: string;
  address: string;
  status: string;
  kyc_status: string;
  is_verified: boolean;
  commission_rate: number;
  avg_rating: number;
  banner_url?: string;
  logo_url?: string;
}

export default function BoutiqueManagement() {
  const [shops, setShops] = useState<ShopItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [toast, setToast] = useState<{ message: string; type: "success" | "error" } | null>(null);

  async function fetchShops() {
    setLoading(true);
    try {
      const { data, error } = await supabase.from("shops").select("*").order("created_at", { ascending: false });
      if (error) throw error;
      setShops((data as ShopItem[]) || []);
    } catch (e: any) {
      console.error("Error loading shops:", e);
      setToast({ message: "Failed to load boutiques: " + e.message, type: "error" });
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchShops();
  }, []);

  async function updateShopStatus(shopId: string, newStatus: string, verified: boolean) {
    setActionLoading(shopId);
    try {
      const { error } = await supabase
        .from("shops")
        .update({ status: newStatus, is_verified: verified, updated_at: new Date().toISOString() })
        .eq("id", shopId);
      if (error) throw error;

      setShops((prev) =>
        prev.map((s) => (s.id === shopId ? { ...s, status: newStatus, is_verified: verified } : s))
      );
      setToast({
        message: `Boutique status updated to '${newStatus}' successfully!`,
        type: "success",
      });
    } catch (e: any) {
      setToast({ message: "Failed to update shop: " + e.message, type: "error" });
    } finally {
      setActionLoading(null);
    }
  }

  const filteredShops = shops.filter(
    (s) =>
      s.name.toLowerCase().includes(search.toLowerCase()) ||
      s.address.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div>
      {/* Toast Notification */}
      {toast && (
        <div
          style={{
            position: "fixed",
            top: "24px",
            right: "24px",
            backgroundColor: toast.type === "success" ? "#064e3b" : "#7f1d1d",
            color: toast.type === "success" ? "#6ee7b7" : "#fca5a5",
            padding: "12px 20px",
            borderRadius: "8px",
            boxShadow: "0 10px 15px -3px rgba(0,0,0,0.5)",
            zIndex: 9999,
            display: "flex",
            alignItems: "center",
            gap: "8px",
            fontSize: "14px",
            fontWeight: "500",
          }}
        >
          {toast.type === "success" ? <CheckCircle size={18} /> : <XCircle size={18} />}
          {toast.message}
          <button
            onClick={() => setToast(null)}
            style={{ background: "none", border: "none", color: "inherit", cursor: "pointer", marginLeft: "12px" }}
          >
            ✕
          </button>
        </div>
      )}

      {/* Header Bar */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "24px", flexWrap: "wrap", gap: "16px" }}>
        <div>
          <h2 style={{ fontSize: "20px", fontWeight: "700", color: "#f8fafc", margin: 0 }}>
            Verified Boutiques &amp; KYC Hub
          </h2>
          <p style={{ color: "#94a3b8", fontSize: "13px", marginTop: "4px" }}>
            Review seller KYC documents, verify Jaipur boutiques, and monitor commission contracts.
          </p>
        </div>
        <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
          <div style={{ position: "relative" }}>
            <Search size={16} color="#64748b" style={{ position: "absolute", left: "12px", top: "10px" }} />
            <input
              type="text"
              placeholder="Search boutique or address..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{
                backgroundColor: "#131b2e",
                border: "1px solid #334155",
                borderRadius: "8px",
                color: "#f8fafc",
                padding: "8px 12px 8px 36px",
                fontSize: "13px",
                width: "240px",
                outline: "none",
              }}
            />
          </div>
          <button
            onClick={fetchShops}
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
            Refresh
          </button>
        </div>
      </div>

      {/* Boutiques List */}
      {loading ? (
        <div style={{ padding: "48px", textAlign: "center", color: "#94a3b8", backgroundColor: "#131b2e", borderRadius: "12px" }}>
          Loading live boutique directory...
        </div>
      ) : filteredShops.length === 0 ? (
        <div style={{ padding: "48px", textAlign: "center", color: "#94a3b8", backgroundColor: "#131b2e", borderRadius: "12px" }}>
          No boutiques found matching "{search}".
        </div>
      ) : (
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(340px, 1fr))", gap: "20px" }}>
          {filteredShops.map((shop) => (
            <div
              key={shop.id}
              style={{
                backgroundColor: "#131b2e",
                border: "1px solid #1e293b",
                borderRadius: "14px",
                overflow: "hidden",
                display: "flex",
                flexDirection: "column",
              }}
            >
              {/* Banner Image */}
              {shop.banner_url && (
                <div
                  style={{
                    height: "120px",
                    backgroundImage: `url(${shop.banner_url})`,
                    backgroundSize: "cover",
                    backgroundPosition: "center",
                    position: "relative",
                  }}
                >
                  <div style={{ position: "absolute", top: "12px", right: "12px" }}>
                    <span
                      style={{
                        backgroundColor: shop.status === "verified" ? "#064e3b" : "#7f1d1d",
                        color: shop.status === "verified" ? "#6ee7b7" : "#fca5a5",
                        padding: "4px 10px",
                        borderRadius: "9999px",
                        fontSize: "11px",
                        fontWeight: "700",
                        textTransform: "uppercase",
                      }}
                    >
                      {shop.status}
                    </span>
                  </div>
                </div>
              )}

              {/* Shop Content */}
              <div style={{ padding: "20px", flex: 1, display: "flex", flexDirection: "column" }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "8px" }}>
                  <h3 style={{ fontSize: "16px", fontWeight: "700", color: "#ffffff", margin: 0 }}>
                    {shop.name}
                  </h3>
                  <div style={{ display: "flex", alignItems: "center", gap: "4px", color: "#eab308", fontSize: "13px", fontWeight: "600" }}>
                    <Star size={14} fill="#eab308" /> {shop.avg_rating || 4.8}
                  </div>
                </div>

                <p style={{ color: "#94a3b8", fontSize: "13px", marginBottom: "16px", lineHeight: "1.5" }}>
                  {shop.description || shop.address}
                </p>

                <div style={{ display: "flex", flexDirection: "column", gap: "8px", fontSize: "12px", color: "#cbd5e1", marginBottom: "20px" }}>
                  <div style={{ display: "flex", justifyContent: "space-between" }}>
                    <span style={{ color: "#64748b" }}>Address:</span>
                    <span style={{ fontWeight: "500", textAlign: "right" }}>{shop.address}</span>
                  </div>
                  <div style={{ display: "flex", justifyContent: "space-between" }}>
                    <span style={{ color: "#64748b" }}>Commission Rate:</span>
                    <span style={{ fontWeight: "600", color: "#10b981" }}>{shop.commission_rate || 10.0}%</span>
                  </div>
                  <div style={{ display: "flex", justifyContent: "space-between" }}>
                    <span style={{ color: "#64748b" }}>KYC Status:</span>
                    <span style={{ fontWeight: "600", color: "#38bdf8", textTransform: "capitalize" }}>
                      {shop.kyc_status || "verified"}
                    </span>
                  </div>
                </div>

                {/* Actions */}
                <div style={{ marginTop: "auto", display: "flex", gap: "10px" }}>
                  {shop.status !== "verified" ? (
                    <button
                      onClick={() => updateShopStatus(shop.id, "verified", true)}
                      disabled={actionLoading === shop.id}
                      style={{
                        flex: 1,
                        backgroundColor: "#059669",
                        color: "#ffffff",
                        border: "none",
                        borderRadius: "8px",
                        padding: "10px",
                        fontSize: "13px",
                        fontWeight: "600",
                        cursor: "pointer",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        gap: "6px",
                      }}
                    >
                      <ShieldCheck size={16} /> Verify Boutique
                    </button>
                  ) : (
                    <button
                      onClick={() => updateShopStatus(shop.id, "suspended", false)}
                      disabled={actionLoading === shop.id}
                      style={{
                        flex: 1,
                        backgroundColor: "#dc2626",
                        color: "#ffffff",
                        border: "none",
                        borderRadius: "8px",
                        padding: "10px",
                        fontSize: "13px",
                        fontWeight: "600",
                        cursor: "pointer",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        gap: "6px",
                      }}
                    >
                      <ShieldAlert size={16} /> Suspend
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

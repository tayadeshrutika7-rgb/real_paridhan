
"use client";

import React, { useEffect, useState } from "react";
import { supabase } from "../lib/supabase";
import {
  Store,
  ShieldCheck,
  ShieldAlert,
  CheckCircle,
  XCircle,
  Search,
  RefreshCw,
  Star,
  FileText,
  User,
  CreditCard,
  Phone,
  Mail,
  Building,
  ExternalLink,
  Clock,
  AlertCircle
} from "lucide-react";

export interface ShopItem {
  id: string;
  seller_id: string;
  name: string;
  owner_name?: string;
  description?: string;
  address: string;
  status: string;
  kyc_status: string;
  is_verified: boolean;
  commission_rate: number;
  avg_rating: number;
  banner_url?: string;
  logo_url?: string;
  contact_phone?: string;
  contact_email?: string;
  gstin?: string;
  pan_number?: string;
  trade_license_number?: string;
  aadhaar_number?: string;
  business_type?: string;
  bank_account_number?: string;
  bank_ifsc?: string;
  bank_name?: string;
  bank_account_name?: string;
  kyc_documents?: string[];
  created_at?: string;
}

export default function BoutiqueManagement() {
  const [shops, setShops] = useState<ShopItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [activeFilter, setActiveFilter] = useState<"all" | "pending" | "verified">("all");
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [toast, setToast] = useState<{ message: string; type: "success" | "error" } | null>(null);

  async function fetchShops() {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from("shops")
        .select("*")
        .order("created_at", { ascending: false });
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
      const kycStatusVal = verified ? "verified" : newStatus === "pending" ? "pending" : "rejected";
      const { error } = await supabase
        .from("shops")
        .update({
          status: newStatus,
          is_verified: verified,
          kyc_status: kycStatusVal,
          updated_at: new Date().toISOString(),
        })
        .eq("id", shopId);
      if (error) throw error;

      setShops((prev) =>
        prev.map((s) =>
          s.id === shopId ? { ...s, status: newStatus, is_verified: verified, kyc_status: kycStatusVal } : s
        )
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

  const pendingCount = shops.filter((s) => s.status !== "verified" || s.kyc_status === "pending").length;

  const filteredShops = shops.filter((s) => {
    const matchesSearch =
      s.name.toLowerCase().includes(search.toLowerCase()) ||
      (s.owner_name && s.owner_name.toLowerCase().includes(search.toLowerCase())) ||
      (s.address && s.address.toLowerCase().includes(search.toLowerCase())) ||
      (s.gstin && s.gstin.toLowerCase().includes(search.toLowerCase()));

    if (!matchesSearch) return false;

    if (activeFilter === "pending") {
      return s.status !== "verified" || s.kyc_status === "pending";
    }
    if (activeFilter === "verified") {
      return s.status === "verified";
    }
    return true;
  });

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
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: "20px",
          flexWrap: "wrap",
          gap: "16px",
        }}
      >
        <div>
          <h2 style={{ fontSize: "20px", fontWeight: "700", color: "#f8fafc", margin: 0 }}>
            Verified Boutiques &amp; KYC Verification
          </h2>
          <p style={{ color: "#94a3b8", fontSize: "13px", marginTop: "4px" }}>
            Review seller shop profiles, inspect submitted GSTIN/PAN &amp; bank details, and approve live boutique storefronts.
          </p>
        </div>
        <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
          <div style={{ position: "relative" }}>
            <Search size={16} color="#64748b" style={{ position: "absolute", left: "12px", top: "10px" }} />
            <input
              type="text"
              placeholder="Search boutique, owner, GSTIN..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{
                backgroundColor: "#131b2e",
                border: "1px solid #334155",
                borderRadius: "8px",
                color: "#f8fafc",
                padding: "8px 12px 8px 36px",
                fontSize: "13px",
                width: "260px",
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

      {/* Filter Tabs */}
      <div style={{ display: "flex", gap: "8px", marginBottom: "20px" }}>
        <button
          onClick={() => setActiveFilter("all")}
          style={{
            padding: "8px 16px",
            borderRadius: "8px",
            border: `1px solid ${activeFilter === "all" ? "#38bdf8" : "#1e293b"}`,
            backgroundColor: activeFilter === "all" ? "#0284c71a" : "#0d1322",
            color: activeFilter === "all" ? "#38bdf8" : "#94a3b8",
            fontSize: "13px",
            fontWeight: "600",
            cursor: "pointer",
          }}
        >
          All Shops ({shops.length})
        </button>
        <button
          onClick={() => setActiveFilter("pending")}
          style={{
            padding: "8px 16px",
            borderRadius: "8px",
            border: `1px solid ${activeFilter === "pending" ? "#f59e0b" : "#1e293b"}`,
            backgroundColor: activeFilter === "pending" ? "#f59e0b1a" : "#0d1322",
            color: activeFilter === "pending" ? "#fbbf24" : "#94a3b8",
            fontSize: "13px",
            fontWeight: "600",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            gap: "6px",
          }}
        >
          <Clock size={14} /> Pending Approval ({pendingCount})
        </button>
        <button
          onClick={() => setActiveFilter("verified")}
          style={{
            padding: "8px 16px",
            borderRadius: "8px",
            border: `1px solid ${activeFilter === "verified" ? "#10b981" : "#1e293b"}`,
            backgroundColor: activeFilter === "verified" ? "#10b9811a" : "#0d1322",
            color: activeFilter === "verified" ? "#34d399" : "#94a3b8",
            fontSize: "13px",
            fontWeight: "600",
            cursor: "pointer",
          }}
        >
          Verified Boutiques ({shops.filter((s) => s.status === "verified").length})
        </button>
      </div>

      {/* Boutiques List */}
      {loading ? (
        <div style={{ padding: "48px", textAlign: "center", color: "#94a3b8", backgroundColor: "#131b2e", borderRadius: "12px" }}>
          Loading live boutique directory...
        </div>
      ) : filteredShops.length === 0 ? (
        <div style={{ padding: "48px", textAlign: "center", color: "#94a3b8", backgroundColor: "#131b2e", borderRadius: "12px" }}>
          No boutiques found matching your criteria.
        </div>
      ) : (
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(360px, 1fr))", gap: "20px" }}>
          {filteredShops.map((shop) => (
            <div
              key={shop.id}
              style={{
                backgroundColor: "#131b2e",
                border: `1px solid ${shop.status === "verified" ? "#1e293b" : "#f59e0b50"}`,
                borderRadius: "14px",
                overflow: "hidden",
                display: "flex",
                flexDirection: "column",
                boxShadow: shop.status !== "verified" ? "0 0 15px rgba(245,158,11,0.08)" : "none",
              }}
            >
              {/* Header Status Strip */}
              <div
                style={{
                  padding: "12px 18px",
                  backgroundColor: shop.status === "verified" ? "#064e3b20" : "#f59e0b15",
                  borderBottom: "1px solid #1e293b",
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                }}
              >
                <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                  <Store size={16} color={shop.status === "verified" ? "#34d399" : "#fbbf24"} />
                  <span style={{ fontSize: "14px", fontWeight: "700", color: "#ffffff" }}>{shop.name}</span>
                </div>
                <span
                  style={{
                    backgroundColor: shop.status === "verified" ? "#064e3b" : "#78350f",
                    color: shop.status === "verified" ? "#6ee7b7" : "#fde68a",
                    padding: "3px 8px",
                    borderRadius: "9999px",
                    fontSize: "11px",
                    fontWeight: "700",
                    textTransform: "uppercase",
                  }}
                >
                  {shop.status}
                </span>
              </div>

              {/* Shop Content */}
              <div style={{ padding: "18px", flex: 1, display: "flex", flexDirection: "column" }}>
                {shop.description && (
                  <p style={{ color: "#94a3b8", fontSize: "12px", marginBottom: "14px", lineHeight: "1.4" }}>
                    {shop.description}
                  </p>
                )}

                {/* Grid of Verified / Submitted Details */}
                <div
                  style={{
                    backgroundColor: "#0d1322",
                    padding: "12px",
                    borderRadius: "10px",
                    border: "1px solid #1e293b",
                    display: "flex",
                    flexDirection: "column",
                    gap: "8px",
                    fontSize: "12px",
                    color: "#cbd5e1",
                    marginBottom: "16px",
                  }}
                >
                  {shop.owner_name && (
                    <div style={{ display: "flex", justifyContent: "space-between" }}>
                      <span style={{ color: "#64748b", display: "flex", alignItems: "center", gap: "4px" }}>
                        <User size={12} /> Owner:
                      </span>
                      <span style={{ fontWeight: "600", color: "#f8fafc" }}>{shop.owner_name}</span>
                    </div>
                  )}

                  <div style={{ display: "flex", justifyContent: "space-between" }}>
                    <span style={{ color: "#64748b" }}>Address:</span>
                    <span style={{ fontWeight: "500", textAlign: "right", maxWidth: "200px" }}>{shop.address}</span>
                  </div>

                  {shop.contact_phone && (
                    <div style={{ display: "flex", justifyContent: "space-between" }}>
                      <span style={{ color: "#64748b", display: "flex", alignItems: "center", gap: "4px" }}>
                        <Phone size={12} /> Contact:
                      </span>
                      <span style={{ fontWeight: "500" }}>{shop.contact_phone}</span>
                    </div>
                  )}

                  {shop.gstin && (
                    <div style={{ display: "flex", justifyContent: "space-between" }}>
                      <span style={{ color: "#64748b", display: "flex", alignItems: "center", gap: "4px" }}>
                        <FileText size={12} /> GSTIN:
                      </span>
                      <span style={{ fontWeight: "700", color: "#38bdf8", fontFamily: "monospace" }}>{shop.gstin}</span>
                    </div>
                  )}

                  {shop.pan_number && (
                    <div style={{ display: "flex", justifyContent: "space-between" }}>
                      <span style={{ color: "#64748b", display: "flex", alignItems: "center", gap: "4px" }}>
                        <CreditCard size={12} /> PAN:
                      </span>
                      <span style={{ fontWeight: "700", color: "#e2e8f0", fontFamily: "monospace" }}>{shop.pan_number}</span>
                    </div>
                  )}

                  {shop.bank_account_number && (
                    <div style={{ display: "flex", justifyContent: "space-between" }}>
                      <span style={{ color: "#64748b", display: "flex", alignItems: "center", gap: "4px" }}>
                        <Building size={12} /> Bank / IFSC:
                      </span>
                      <span style={{ fontWeight: "500", color: "#94a3b8" }}>
                        {shop.bank_name || "Bank"} &bull; {shop.bank_ifsc || ""}
                      </span>
                    </div>
                  )}

                  <div style={{ display: "flex", justifyContent: "space-between", borderTop: "1px solid #1e293b", paddingTop: "6px" }}>
                    <span style={{ color: "#64748b" }}>Commission:</span>
                    <span style={{ fontWeight: "700", color: "#10b981" }}>{shop.commission_rate || 10.0}%</span>
                  </div>
                </div>

                {/* KYC Documents Preview */}
                {shop.kyc_documents && shop.kyc_documents.length > 0 && (
                  <div style={{ marginBottom: "16px" }}>
                    <div style={{ fontSize: "11px", fontWeight: "700", color: "#64748b", textTransform: "uppercase", marginBottom: "6px" }}>
                      Attached KYC Proofs ({shop.kyc_documents.length})
                    </div>
                    <div style={{ display: "flex", gap: "8px", flexWrap: "wrap" }}>
                      {shop.kyc_documents.map((doc, i) => (
                        <a
                          key={i}
                          href={doc}
                          target="_blank"
                          rel="noreferrer"
                          style={{
                            display: "inline-flex",
                            alignItems: "center",
                            gap: "4px",
                            padding: "4px 8px",
                            backgroundColor: "#090d16",
                            border: "1px solid #334155",
                            borderRadius: "6px",
                            color: "#38bdf8",
                            fontSize: "11px",
                            textDecoration: "none",
                          }}
                        >
                          <FileText size={12} /> Proof #{i + 1} <ExternalLink size={10} />
                        </a>
                      ))}
                    </div>
                  </div>
                )}

                {/* Actions */}
                <div style={{ marginTop: "auto", display: "flex", gap: "10px" }}>
                  {shop.status !== "verified" ? (
                    <>
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
                          fontWeight: "700",
                          cursor: "pointer",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          gap: "6px",
                        }}
                      >
                        <ShieldCheck size={16} /> Approve &amp; Verify Boutique
                      </button>
                      <button
                        onClick={() => updateShopStatus(shop.id, "rejected", false)}
                        disabled={actionLoading === shop.id}
                        style={{
                          backgroundColor: "#7f1d1d",
                          color: "#fca5a5",
                          border: "none",
                          borderRadius: "8px",
                          padding: "10px 14px",
                          fontSize: "13px",
                          fontWeight: "600",
                          cursor: "pointer",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          gap: "4px",
                        }}
                      >
                        <ShieldAlert size={16} /> Reject
                      </button>
                    </>
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
                      <ShieldAlert size={16} /> Suspend Live Access
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

"use client";

import React, { useEffect, useState } from "react";
import { supabase } from "../lib/supabase";
import { Sliders, Save, RefreshCw, CheckCircle, Percent, DollarSign, ToggleLeft, ToggleRight } from "lucide-react";

export default function PlatformConfigEditor() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: "success" | "error" } | null>(null);

  // Editable config state
  const [commissionRate, setCommissionRate] = useState<number>(10.0);
  const [baseFee, setBaseFee] = useState<number>(30.0);
  const [perKmRate, setPerKmRate] = useState<number>(5.0);
  const [freeAbove, setFreeAbove] = useState<number>(999.0);
  const [bargainingEnabled, setBargainingEnabled] = useState<boolean>(true);
  const [aiHelpdeskEnabled, setAiHelpdeskEnabled] = useState<boolean>(true);
  const [skinToneRecs, setSkinToneRecs] = useState<boolean>(false);

  async function fetchConfig() {
    setLoading(true);
    try {
      const { data, error } = await supabase.from("platform_config").select("*");
      if (error) throw error;

      (data || []).forEach((row) => {
        if (row.key === "default_commission_rate") {
          setCommissionRate(row.value?.rate ?? 10.0);
        } else if (row.key === "delivery_fee_rules") {
          setBaseFee(row.value?.base_fee ?? 30.0);
          setPerKmRate(row.value?.per_km_rate ?? 5.0);
          setFreeAbove(row.value?.free_above ?? 999.0);
        } else if (row.key === "feature_flags") {
          setBargainingEnabled(row.value?.bargaining_enabled ?? true);
          setAiHelpdeskEnabled(row.value?.ai_helpdesk_enabled ?? true);
          setSkinToneRecs(row.value?.skin_tone_recommendations ?? false);
        }
      });
    } catch (e: any) {
      console.error("Error fetching config:", e);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchConfig();
  }, []);

  async function handleSave() {
    setSaving(true);
    try {
      const updates: { key: string; value: any }[] = [
        {
          key: "default_commission_rate",
          value: { rate: Number(commissionRate) },
        },
        {
          key: "delivery_fee_rules",
          value: {
            base_fee: Number(baseFee),
            per_km_rate: Number(perKmRate),
            free_above: Number(freeAbove),
          },
        },
        {
          key: "feature_flags",
          value: {
            bargaining_enabled: bargainingEnabled,
            ai_helpdesk_enabled: aiHelpdeskEnabled,
            skin_tone_recommendations: skinToneRecs,
          },
        },
      ];

      for (const item of updates) {
        const { error } = await supabase
          .from("platform_config")
          .upsert(item as any);
        if (error) throw error;
      }

      setToast({ message: "Platform configuration updated successfully in hosted Supabase!", type: "success" });
    } catch (e: any) {
      setToast({ message: "Failed to save config: " + e.message, type: "error" });
    } finally {
      setSaving(false);
    }
  }

  const cardStyle: React.CSSProperties = {
    backgroundColor: "#131b2e",
    border: "1px solid #1e293b",
    borderRadius: "14px",
    padding: "24px",
    marginBottom: "20px",
  };

  const inputStyle: React.CSSProperties = {
    backgroundColor: "#0f172a",
    border: "1px solid #334155",
    borderRadius: "8px",
    color: "#ffffff",
    padding: "10px 14px",
    fontSize: "14px",
    fontWeight: "600",
    width: "100%",
    outline: "none",
  };

  return (
    <div>
      {/* Toast */}
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
          <CheckCircle size={18} />
          {toast.message}
          <button
            onClick={() => setToast(null)}
            style={{ background: "none", border: "none", color: "inherit", cursor: "pointer", marginLeft: "12px" }}
          >
            ✕
          </button>
        </div>
      )}

      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "24px", flexWrap: "wrap", gap: "16px" }}>
        <div>
          <h2 style={{ fontSize: "20px", fontWeight: "700", color: "#f8fafc", margin: 0 }}>
            Platform Configuration &amp; Rule Engine
          </h2>
          <p style={{ color: "#94a3b8", fontSize: "13px", marginTop: "4px" }}>
            Dynamically adjust platform fee splits, hyper-local delivery rules, and feature flags.
          </p>
        </div>
        <div style={{ display: "flex", gap: "12px" }}>
          <button
            onClick={fetchConfig}
            disabled={loading || saving}
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
              cursor: "pointer",
            }}
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} /> Reset
          </button>
          <button
            onClick={handleSave}
            disabled={loading || saving}
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: "8px",
              backgroundColor: "#2563eb",
              color: "#ffffff",
              border: "none",
              borderRadius: "8px",
              padding: "8px 20px",
              fontSize: "13px",
              fontWeight: "700",
              cursor: "pointer",
            }}
          >
            <Save size={16} /> {saving ? "Saving Changes..." : "Save Configuration"}
          </button>
        </div>
      </div>

      {/* Forms Grid */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(360px, 1fr))", gap: "20px" }}>
        {/* Section 1: Marketplace Commission */}
        <div style={cardStyle}>
          <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "16px" }}>
            <div style={{ width: "32px", height: "32px", borderRadius: "8px", backgroundColor: "#312e81", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <Percent size={18} color="#818cf8" />
            </div>
            <div>
              <h3 style={{ fontSize: "16px", fontWeight: "700", color: "#f8fafc", margin: 0 }}>
                Default Marketplace Commission
              </h3>
              <p style={{ fontSize: "12px", color: "#64748b", margin: 0 }}>Auto-split rate applied on seller payouts</p>
            </div>
          </div>

          <div style={{ marginBottom: "16px" }}>
            <label style={{ display: "block", fontSize: "13px", color: "#cbd5e1", marginBottom: "6px" }}>
              Commission Percentage (%):
            </label>
            <input
              type="number"
              step="0.5"
              value={commissionRate}
              onChange={(e) => setCommissionRate(Number(e.target.value))}
              style={inputStyle}
            />
          </div>
          <div style={{ fontSize: "12px", color: "#10b981", backgroundColor: "#064e3b20", padding: "8px 12px", borderRadius: "6px", border: "1px solid #064e3b" }}>
            Current Rule: Seller receives {(100 - commissionRate).toFixed(1)}%, Platform retains {commissionRate}%
          </div>
        </div>

        {/* Section 2: Hyperlocal Delivery Rules */}
        <div style={cardStyle}>
          <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "16px" }}>
            <div style={{ width: "32px", height: "32px", borderRadius: "8px", backgroundColor: "#713f12", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <DollarSign size={18} color="#eab308" />
            </div>
            <div>
              <h3 style={{ fontSize: "16px", fontWeight: "700", color: "#f8fafc", margin: 0 }}>
                Hyperlocal Delivery Fee Calculation
              </h3>
              <p style={{ fontSize: "12px", color: "#64748b", margin: 0 }}>Distance-based dynamic fee matrix</p>
            </div>
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "12px", marginBottom: "12px" }}>
            <div>
              <label style={{ display: "block", fontSize: "12px", color: "#cbd5e1", marginBottom: "4px" }}>
                Base Fee (₹):
              </label>
              <input
                type="number"
                value={baseFee}
                onChange={(e) => setBaseFee(Number(e.target.value))}
                style={inputStyle}
              />
            </div>
            <div>
              <label style={{ display: "block", fontSize: "12px", color: "#cbd5e1", marginBottom: "4px" }}>
                Per KM Rate (₹):
              </label>
              <input
                type="number"
                value={perKmRate}
                onChange={(e) => setPerKmRate(Number(e.target.value))}
                style={inputStyle}
              />
            </div>
          </div>

          <div>
            <label style={{ display: "block", fontSize: "12px", color: "#cbd5e1", marginBottom: "4px" }}>
              Free Delivery Threshold (₹):
            </label>
            <input
              type="number"
              value={freeAbove}
              onChange={(e) => setFreeAbove(Number(e.target.value))}
              style={inputStyle}
            />
          </div>
        </div>
      </div>

      {/* Section 3: Feature Flags */}
      <div style={cardStyle}>
        <h3 style={{ fontSize: "16px", fontWeight: "700", color: "#f8fafc", marginBottom: "16px" }}>
          Platform Feature Flags
        </h3>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))", gap: "16px" }}>
          <div
            onClick={() => setBargainingEnabled(!bargainingEnabled)}
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              padding: "14px 18px",
              backgroundColor: "#0f172a",
              borderRadius: "10px",
              border: "1px solid #1e293b",
              cursor: "pointer",
            }}
          >
            <div>
              <div style={{ fontWeight: "600", color: "#f8fafc", fontSize: "14px" }}>Dynamic Bargaining Engine</div>
              <div style={{ fontSize: "11px", color: "#64748b" }}>1-on-1 negotiation counter-offers</div>
            </div>
            {bargainingEnabled ? <ToggleRight size={28} color="#10b981" /> : <ToggleLeft size={28} color="#64748b" />}
          </div>

          <div
            onClick={() => setAiHelpdeskEnabled(!aiHelpdeskEnabled)}
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              padding: "14px 18px",
              backgroundColor: "#0f172a",
              borderRadius: "10px",
              border: "1px solid #1e293b",
              cursor: "pointer",
            }}
          >
            <div>
              <div style={{ fontWeight: "600", color: "#f8fafc", fontSize: "14px" }}>AI Stylist &amp; Helpdesk</div>
              <div style={{ fontSize: "11px", color: "#64748b" }}>Automated fashion support</div>
            </div>
            {aiHelpdeskEnabled ? <ToggleRight size={28} color="#10b981" /> : <ToggleLeft size={28} color="#64748b" />}
          </div>

          <div
            onClick={() => setSkinToneRecs(!skinToneRecs)}
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              padding: "14px 18px",
              backgroundColor: "#0f172a",
              borderRadius: "10px",
              border: "1px solid #1e293b",
              cursor: "pointer",
            }}
          >
            <div>
              <div style={{ fontWeight: "600", color: "#f8fafc", fontSize: "14px" }}>Skin Tone Color Analysis</div>
              <div style={{ fontSize: "11px", color: "#64748b" }}>Personalized palette recommendations</div>
            </div>
            {skinToneRecs ? <ToggleRight size={28} color="#10b981" /> : <ToggleLeft size={28} color="#64748b" />}
          </div>
        </div>
      </div>
    </div>
  );
}

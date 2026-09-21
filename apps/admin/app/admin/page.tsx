"use client";

import React, { useState } from "react";
import { 
  Store, 
  TrendingUp, 
  Truck, 
  ShoppingBag, 
  Users, 
  Sliders, 
  Tag, 
  ShieldCheck,
  Server,
  Zap,
  CheckCircle2,
  ExternalLink
} from "lucide-react";

import OverviewHub from "../../components/OverviewHub";
import BoutiqueManagement from "../../components/BoutiqueManagement";
import UserManagement from "../../components/UserManagement";
import OrderManagement from "../../components/OrderManagement";
import CatalogOversight from "../../components/CatalogOversight";
import PlatformConfigEditor from "../../components/PlatformConfigEditor";

export default function AdminDashboardPage() {
  const [activeTab, setActiveTab] = useState<"overview" | "shops" | "users" | "orders" | "products" | "config">("overview");

  const navItems = [
    { id: "overview", label: "Overview & Telemetry", icon: <TrendingUp size={18} /> },
    { id: "shops", label: "Boutiques & KYC", icon: <Store size={18} /> },
    { id: "users", label: "User Ecosystem", icon: <Users size={18} /> },
    { id: "orders", label: "Orders & Dispatch", icon: <ShoppingBag size={18} /> },
    { id: "products", label: "Catalog & Pricing", icon: <Tag size={18} /> },
    { id: "config", label: "Platform Rules", icon: <Sliders size={18} /> },
  ];

  return (
    <div style={{ minHeight: "calc(100vh - 65px)", backgroundColor: "#090d16", color: "#f1f5f9", display: "flex", flexDirection: "column" }}>
      {/* Top Admin Sub-Header */}
      <div
        style={{
          borderBottom: "1px solid #1e293b",
          backgroundColor: "#0d1322",
          padding: "16px 24px",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
          <div
            style={{
              width: "36px",
              height: "36px",
              borderRadius: "10px",
              backgroundColor: "#f43f5e",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: "#fff",
              fontSize: "18px",
            }}
          >
            🛡️
          </div>
          <div>
            <h1 style={{ fontSize: "18px", fontWeight: "700", letterSpacing: "-0.02em", color: "#ffffff", margin: 0 }}>
              PARIDHAN Admin Console
            </h1>
            <p style={{ color: "#94a3b8", fontSize: "12px", margin: 0 }}>
              Hyperlocal Fashion Marketplace &bull; Cloud Backend: <code>faqtswmhgintutwvnkyy</code>
            </p>
          </div>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
          <span
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: "6px",
              backgroundColor: "#064e3b",
              color: "#6ee7b7",
              padding: "6px 14px",
              borderRadius: "9999px",
              fontSize: "12px",
              fontWeight: "600",
            }}
          >
            <span style={{ width: "8px", height: "8px", borderRadius: "50%", backgroundColor: "#10b981" }}></span>
            Hosted Supabase Live
          </span>
        </div>
      </div>

      {/* Main Layout Body */}
      <div style={{ display: "flex", flex: 1 }}>
        {/* Navigation Sidebar */}
        <aside
          style={{
            width: "250px",
            borderRight: "1px solid #1e293b",
            backgroundColor: "#0b101d",
            padding: "24px 16px",
            display: "flex",
            flexDirection: "column",
            gap: "6px",
          }}
        >
          <div style={{ fontSize: "11px", fontWeight: "700", color: "#64748b", textTransform: "uppercase", paddingLeft: "12px", marginBottom: "8px", letterSpacing: "1px" }}>
            Admin Oversight Hub
          </div>
          {navItems.map((item) => {
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id as any)}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "12px",
                  padding: "10px 14px",
                  borderRadius: "10px",
                  border: "none",
                  backgroundColor: isActive ? "#2563eb" : "transparent",
                  color: isActive ? "#ffffff" : "#94a3b8",
                  fontSize: "13px",
                  fontWeight: isActive ? "700" : "500",
                  cursor: "pointer",
                  textAlign: "left",
                  transition: "all 0.15s ease",
                  width: "100%",
                }}
              >
                {item.icon}
                {item.label}
              </button>
            );
          })}

          <div style={{ marginTop: "auto", borderTop: "1px solid #1e293b", paddingTop: "16px" }}>
            <div style={{ padding: "12px", backgroundColor: "#131b2e", borderRadius: "8px", border: "1px solid #1e293b" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "11px", color: "#38bdf8", fontWeight: "600", marginBottom: "4px" }}>
                <Server size={12} /> Live API Status
              </div>
              <div style={{ fontSize: "11px", color: "#94a3b8" }}>
                22/22 Tables Online
              </div>
            </div>
          </div>
        </aside>

        {/* Content Area */}
        <main style={{ flex: 1, padding: "32px", overflowY: "auto" }}>
          <div style={{ maxWidth: "1200px", margin: "0 auto" }}>
            {activeTab === "overview" && <OverviewHub />}
            {activeTab === "shops" && <BoutiqueManagement />}
            {activeTab === "users" && <UserManagement />}
            {activeTab === "orders" && <OrderManagement />}
            {activeTab === "products" && <CatalogOversight />}
            {activeTab === "config" && <PlatformConfigEditor />}
          </div>
        </main>
      </div>
    </div>
  );
}

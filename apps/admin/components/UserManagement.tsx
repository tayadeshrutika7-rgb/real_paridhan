"use client";

import React, { useEffect, useState } from "react";
import { supabase } from "../lib/supabase";
import { Users, Search, RefreshCw, Shield, ShoppingBag, Store, Truck } from "lucide-react";

export interface ProfileItem {
  id: string;
  role: "consumer" | "seller" | "delivery" | "admin";
  full_name: string;
  email: string;
  phone: string;
  avatar_url?: string;
  created_at: string;
  accepted_terms_at?: string;
}

export default function UserManagement() {
  const [profiles, setProfiles] = useState<ProfileItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [roleFilter, setRoleFilter] = useState<string>("all");
  const [search, setSearch] = useState("");

  async function fetchUsers() {
    setLoading(true);
    try {
      const { data, error } = await supabase.from("profiles").select("*").order("created_at", { ascending: false });
      if (error) throw error;
      setProfiles((data as ProfileItem[]) || []);
    } catch (e) {
      console.error("Error loading profiles:", e);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchUsers();
  }, []);

  const filteredUsers = profiles.filter((u) => {
    const matchesRole = roleFilter === "all" || u.role === roleFilter;
    const matchesSearch =
      (u.full_name?.toLowerCase().includes(search.toLowerCase()) ?? false) ||
      (u.email?.toLowerCase().includes(search.toLowerCase()) ?? false) ||
      (u.phone?.includes(search) ?? false);
    return matchesRole && matchesSearch;
  });

  const getRoleBadge = (role: string) => {
    switch (role) {
      case "admin":
        return { bg: "#312e81", color: "#818cf8", icon: <Shield size={12} />, label: "Super Admin" };
      case "seller":
        return { bg: "#831843", color: "#f43f5e", icon: <Store size={12} />, label: "Boutique Seller" };
      case "delivery":
        return { bg: "#713f12", color: "#eab308", icon: <Truck size={12} />, label: "Delivery Partner" };
      default:
        return { bg: "#064e3b", color: "#6ee7b7", icon: <ShoppingBag size={12} />, label: "Consumer / Buyer" };
    }
  };

  return (
    <div>
      {/* Header Bar */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "24px", flexWrap: "wrap", gap: "16px" }}>
        <div>
          <h2 style={{ fontSize: "20px", fontWeight: "700", color: "#f8fafc", margin: 0 }}>
            User Ecosystem Directory
          </h2>
          <p style={{ color: "#94a3b8", fontSize: "13px", marginTop: "4px" }}>
            Manage and inspect all accounts across Consumers, Sellers, Riders, and Admins.
          </p>
        </div>
        <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
          <div style={{ position: "relative" }}>
            <Search size={16} color="#64748b" style={{ position: "absolute", left: "12px", top: "10px" }} />
            <input
              type="text"
              placeholder="Search user name, email, phone..."
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
            onClick={fetchUsers}
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

      {/* Role Filter Tabs */}
      <div style={{ display: "flex", gap: "8px", marginBottom: "20px", borderBottom: "1px solid #1e293b", paddingBottom: "12px" }}>
        {[
          { id: "all", label: "All Users" },
          { id: "consumer", label: "Buyers" },
          { id: "seller", label: "Boutique Sellers" },
          { id: "delivery", label: "Delivery Riders" },
          { id: "admin", label: "Administrators" },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setRoleFilter(tab.id)}
            style={{
              backgroundColor: roleFilter === tab.id ? "#2563eb" : "#131b2e",
              color: roleFilter === tab.id ? "#ffffff" : "#94a3b8",
              border: "1px solid",
              borderColor: roleFilter === tab.id ? "#3b82f6" : "#1e293b",
              borderRadius: "8px",
              padding: "6px 14px",
              fontSize: "13px",
              fontWeight: "600",
              cursor: "pointer",
              transition: "all 0.15s ease",
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Table Container */}
      <div style={{ backgroundColor: "#131b2e", border: "1px solid #1e293b", borderRadius: "14px", overflow: "hidden" }}>
        {loading ? (
          <div style={{ padding: "48px", textAlign: "center", color: "#94a3b8" }}>
            Loading live user directory...
          </div>
        ) : filteredUsers.length === 0 ? (
          <div style={{ padding: "48px", textAlign: "center", color: "#94a3b8" }}>
            No users found matching current filters.
          </div>
        ) : (
          <table style={{ width: "100%", borderCollapse: "collapse", textAlign: "left", fontSize: "13px" }}>
            <thead>
              <tr style={{ backgroundColor: "#0f172a", borderBottom: "1px solid #1e293b", color: "#64748b" }}>
                <th style={{ padding: "14px 20px", fontWeight: "600" }}>User / Profile</th>
                <th style={{ padding: "14px 20px", fontWeight: "600" }}>Role</th>
                <th style={{ padding: "14px 20px", fontWeight: "600" }}>Contact Info</th>
                <th style={{ padding: "14px 20px", fontWeight: "600" }}>Terms Accepted</th>
                <th style={{ padding: "14px 20px", fontWeight: "600" }}>Joined</th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.map((user, idx) => {
                const badge = getRoleBadge(user.role);
                return (
                  <tr
                    key={user.id}
                    style={{
                      borderBottom: idx === filteredUsers.length - 1 ? "none" : "1px solid #1e293b",
                      color: "#f8fafc",
                    }}
                  >
                    <td style={{ padding: "14px 20px", display: "flex", alignItems: "center", gap: "12px" }}>
                      <div
                        style={{
                          width: "36px",
                          height: "36px",
                          borderRadius: "50%",
                          backgroundColor: "#1e293b",
                          backgroundImage: user.avatar_url ? `url(${user.avatar_url})` : "none",
                          backgroundSize: "cover",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          color: "#38bdf8",
                          fontWeight: "700",
                          fontSize: "14px",
                        }}
                      >
                        {!user.avatar_url && (user.full_name ? user.full_name[0].toUpperCase() : "U")}
                      </div>
                      <div>
                        <div style={{ fontWeight: "600", color: "#ffffff" }}>{user.full_name || "Unnamed User"}</div>
                        <div style={{ fontSize: "11px", color: "#64748b", fontFamily: "monospace" }}>{user.id}</div>
                      </div>
                    </td>
                    <td style={{ padding: "14px 20px" }}>
                      <span
                        style={{
                          display: "inline-flex",
                          alignItems: "center",
                          gap: "6px",
                          backgroundColor: badge.bg,
                          color: badge.color,
                          padding: "4px 10px",
                          borderRadius: "9999px",
                          fontSize: "11px",
                          fontWeight: "600",
                        }}
                      >
                        {badge.icon} {badge.label}
                      </span>
                    </td>
                    <td style={{ padding: "14px 20px" }}>
                      <div style={{ color: "#cbd5e1" }}>{user.email || "No Email"}</div>
                      <div style={{ fontSize: "11px", color: "#64748b" }}>{user.phone || "No Phone"}</div>
                    </td>
                    <td style={{ padding: "14px 20px" }}>
                      <span style={{ color: user.accepted_terms_at ? "#10b981" : "#eab308", fontWeight: "500" }}>
                        {user.accepted_terms_at ? "Accepted" : "Pending"}
                      </span>
                    </td>
                    <td style={{ padding: "14px 20px", color: "#64748b", fontSize: "12px" }}>
                      {new Date(user.created_at).toLocaleDateString()}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

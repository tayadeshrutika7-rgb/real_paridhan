"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "../../../lib/supabase";
import {
  Truck,
  ShieldCheck,
  User,
  Phone,
  Mail,
  MapPin,
  CreditCard,
  DollarSign,
  CheckCircle2,
  FileText,
} from "lucide-react";

export default function DeliveryProfilePage() {
  const [profile, setProfile] = useState<any>({
    full_name: "Vikram Singh (Johari Rider)",
    email: "delivery1@gm.com",
    phone: "+91 98765 43210",
    vehicle_type: "Motorcycle (Hero Splendor Plus)",
    vehicle_number: "RJ 14 JP 4421",
    verification_status: "verified",
    is_online: true,
  });

  const [remittances, setRemittances] = useState<any[]>([
    { id: "rem-1", order_number: "ORD-882194", amount: 1215.0, status: "pending", date: new Date().toLocaleDateString() },
    { id: "rem-2", order_number: "ORD-601932", amount: 2450.0, status: "remitted", date: "Yesterday" },
  ]);

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
          { label: "Assigned Trips & OTPs", href: "/delivery/orders", active: false },
          { label: "Rider Profile", href: "/delivery/profile", active: true },
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

      <div style={{ maxWidth: "960px", margin: "0 auto", padding: "32px 24px" }}>
        <h1 style={{ fontSize: "26px", fontWeight: "800", color: "#ffffff", margin: "0 0 8px" }}>
          Rider Profile & KYC Credentials
        </h1>
        <p style={{ color: "#94a3b8", fontSize: "14px", margin: "0 0 28px" }}>
          Hyperlocal partner credentials and Cash on Delivery remittance ledger
        </p>

        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "24px" }}>
          {/* Identity & Vehicle Card */}
          <div
            style={{
              backgroundColor: "#0d1322",
              border: "1px solid #1e293b",
              borderRadius: "14px",
              padding: "24px",
            }}
          >
            <div style={{ display: "flex", alignItems: "center", gap: "14px", marginBottom: "20px" }}>
              <div
                style={{
                  width: "52px",
                  height: "52px",
                  borderRadius: "12px",
                  backgroundColor: "#1e293b",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  fontSize: "26px",
                }}
              >
                🛵
              </div>
              <div>
                <h3 style={{ fontSize: "17px", fontWeight: "700", color: "#ffffff", margin: 0 }}>
                  {profile.full_name}
                </h3>
                <div style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "12px", color: "#34d399", marginTop: "2px" }}>
                  <ShieldCheck size={14} /> Verified Partner Status
                </div>
              </div>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: "12px", fontSize: "13px" }}>
              <div style={{ display: "flex", justifyContent: "space-between", color: "#94a3b8" }}>
                <span>Email:</span>
                <span style={{ color: "#ffffff", fontWeight: "600" }}>{profile.email}</span>
              </div>

              <div style={{ display: "flex", justifyContent: "space-between", color: "#94a3b8" }}>
                <span>Phone:</span>
                <span style={{ color: "#ffffff", fontWeight: "600" }}>{profile.phone}</span>
              </div>

              <div style={{ display: "flex", justifyContent: "space-between", color: "#94a3b8" }}>
                <span>Vehicle:</span>
                <span style={{ color: "#ffffff", fontWeight: "600" }}>{profile.vehicle_type}</span>
              </div>

              <div style={{ display: "flex", justifyContent: "space-between", color: "#94a3b8" }}>
                <span>Registration No.:</span>
                <span style={{ color: "#ffffff", fontWeight: "600" }}>{profile.vehicle_number}</span>
              </div>

              <div style={{ display: "flex", justifyContent: "space-between", color: "#94a3b8" }}>
                <span>City Ops Sector:</span>
                <span style={{ color: "#38bdf8", fontWeight: "600" }}>Johari Bazaar, Jaipur (Zone 1)</span>
              </div>
            </div>
          </div>

          {/* COD Remittance Ledger */}
          <div
            style={{
              backgroundColor: "#0d1322",
              border: "1px solid #1e293b",
              borderRadius: "14px",
              padding: "24px",
            }}
          >
            <h3 style={{ fontSize: "16px", fontWeight: "700", color: "#ffffff", margin: "0 0 16px" }}>
              COD Remittance Ledger
            </h3>

            <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
              {remittances.map((r) => (
                <div
                  key={r.id}
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    padding: "12px 14px",
                    backgroundColor: "#090d16",
                    borderRadius: "8px",
                    border: "1px solid #1e293b",
                    fontSize: "13px",
                  }}
                >
                  <div>
                    <div style={{ fontWeight: "700", color: "#ffffff" }}>{r.order_number}</div>
                    <div style={{ fontSize: "11px", color: "#64748b" }}>{r.date}</div>
                  </div>

                  <div style={{ textAlign: "right" }}>
                    <div style={{ fontWeight: "800", color: "#ffffff" }}>₹{r.amount.toLocaleString()}</div>
                    <span
                      style={{
                        fontSize: "10px",
                        fontWeight: "700",
                        textTransform: "uppercase",
                        padding: "2px 6px",
                        borderRadius: "4px",
                        backgroundColor: r.status === "remitted" ? "#10b98120" : "#f59e0b20",
                        color: r.status === "remitted" ? "#34d399" : "#fbbf24",
                      }}
                    >
                      {r.status}
                    </span>
                  </div>
                </div>
              ))}
            </div>

            <div
              style={{
                marginTop: "18px",
                padding: "12px",
                borderRadius: "8px",
                backgroundColor: "#131b2e",
                border: "1px solid #1e293b",
                display: "flex",
                justifyContent: "space-between",
                fontSize: "13px",
              }}
            >
              <span style={{ color: "#94a3b8" }}>Pending Hub Remittance:</span>
              <strong style={{ color: "#fbbf24" }}>₹1,215.00</strong>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

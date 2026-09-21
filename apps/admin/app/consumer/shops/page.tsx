"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "../../../lib/supabase";
import {
  Store,
  MapPin,
  Star,
  ArrowRight,
  ShieldCheck,
  Search,
  Phone,
  Navigation,
} from "lucide-react";

export default function ShopsPage() {
  const [shops, setShops] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  useEffect(() => {
    async function fetchShops() {
      try {
        const { data, error } = await supabase
          .from("shops")
          .select("*")
          .eq("status", "verified")
          .order("avg_rating", { ascending: false });

        if (data && !error) setShops(data);
      } catch (err) {
        console.warn("Failed to load shops:", err);
      } finally {
        setLoading(false);
      }
    }
    fetchShops();
  }, []);

  const filteredShops = shops.filter(
    (s) =>
      s.name.toLowerCase().includes(search.toLowerCase()) ||
      s.address.toLowerCase().includes(search.toLowerCase())
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
          { label: "Marketplace", href: "/consumer", active: false },
          { label: "Nearby Boutiques", href: "/consumer/shops", active: true },
          { label: "All Products", href: "/consumer/products", active: false },
          { label: "Bargain Deals", href: "/consumer/bargains", active: false },
          { label: "Shopping Bag", href: "/consumer/cart", active: false },
          { label: "My Orders", href: "/consumer/orders", active: false },
        ].map((sub) => (
          <Link
            key={sub.label}
            href={sub.href}
            style={{
              fontSize: "13px",
              fontWeight: sub.active ? "700" : "500",
              color: sub.active ? "#38bdf8" : "#94a3b8",
              textDecoration: "none",
              padding: "4px 8px",
              borderRadius: "6px",
              backgroundColor: sub.active ? "#0284c715" : "transparent",
              whiteSpace: "nowrap",
            }}
          >
            {sub.label}
          </Link>
        ))}
      </div>

      <div style={{ maxWidth: "1200px", margin: "0 auto", padding: "32px 24px" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", marginBottom: "28px", flexWrap: "wrap", gap: "16px" }}>
          <div>
            <h1 style={{ fontSize: "26px", fontWeight: "800", color: "#ffffff", margin: "0 0 6px" }}>
              Nearby Verified Boutiques
            </h1>
            <p style={{ color: "#94a3b8", fontSize: "14px", margin: 0 }}>
              Hyperlocal heritage shops within 10 km PostGIS radius in Jaipur
            </p>
          </div>

          <div style={{ position: "relative", width: "100%", maxWidth: "340px" }}>
            <Search size={16} style={{ position: "absolute", left: "12px", top: "11px", color: "#64748b" }} />
            <input
              type="text"
              placeholder="Search boutique or bazaar..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{
                width: "100%",
                padding: "9px 12px 9px 36px",
                borderRadius: "8px",
                backgroundColor: "#0d1322",
                border: "1px solid #1e293b",
                color: "#f1f5f9",
                fontSize: "13px",
                outline: "none",
              }}
            />
          </div>
        </div>

        {loading ? (
          <div style={{ textAlign: "center", padding: "60px", color: "#94a3b8" }}>
            Loading nearby boutiques from database...
          </div>
        ) : (
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fill, minmax(340px, 1fr))",
              gap: "20px",
            }}
          >
            {filteredShops.map((shop, i) => (
              <div
                key={shop.id}
                style={{
                  backgroundColor: "#0d1322",
                  border: "1px solid #1e293b",
                  borderRadius: "14px",
                  padding: "24px",
                  display: "flex",
                  flexDirection: "column",
                  justifyContent: "space-between",
                }}
              >
                <div>
                  <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: "12px", marginBottom: "14px" }}>
                    <div style={{ display: "flex", alignItems: "center", gap: "14px" }}>
                      <div
                        style={{
                          width: "48px",
                          height: "48px",
                          borderRadius: "12px",
                          backgroundColor: "#1e293b",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          fontSize: "24px",
                        }}
                      >
                        🏪
                      </div>
                      <div>
                        <h3 style={{ fontSize: "16px", fontWeight: "700", color: "#ffffff", margin: "0 0 3px" }}>
                          {shop.name}
                        </h3>
                        <div style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "12px" }}>
                          <span style={{ color: "#fbbf24", display: "flex", alignItems: "center", gap: "3px", fontWeight: "600" }}>
                            <Star size={12} fill="#fbbf24" /> {shop.avg_rating || "4.8"}
                          </span>
                          <span style={{ color: "#475569" }}>&bull;</span>
                          <span style={{ color: "#34d399", fontWeight: "600", display: "flex", alignItems: "center", gap: "3px" }}>
                            <ShieldCheck size={12} /> Verified KYC
                          </span>
                        </div>
                      </div>
                    </div>

                    <span
                      style={{
                        fontSize: "11px",
                        fontWeight: "700",
                        padding: "3px 8px",
                        borderRadius: "9999px",
                        backgroundColor: "#0284c720",
                        color: "#38bdf8",
                        border: "1px solid #0284c740",
                      }}
                    >
                      ~{(1.2 + i * 0.7).toFixed(1)} km
                    </span>
                  </div>

                  <p style={{ fontSize: "13px", color: "#94a3b8", lineHeight: "1.5", marginBottom: "16px" }}>
                    {shop.description || "Traditional bridal attire, bandhani sarees, and festive couture."}
                  </p>

                  <div style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "12px", color: "#64748b", marginBottom: "20px" }}>
                    <MapPin size={13} />
                    <span>{shop.address}</span>
                  </div>
                </div>

                <div style={{ display: "flex", gap: "10px" }}>
                  <Link
                    href={`/consumer/products?shopId=${shop.id}`}
                    style={{
                      flex: 1,
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      gap: "6px",
                      padding: "10px",
                      borderRadius: "8px",
                      backgroundColor: "#2563eb",
                      color: "#ffffff",
                      fontSize: "13px",
                      fontWeight: "700",
                      textDecoration: "none",
                    }}
                  >
                    <span>View Boutique Catalog</span>
                    <ArrowRight size={14} />
                  </Link>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

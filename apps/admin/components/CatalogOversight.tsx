"use client";

import React, { useEffect, useState } from "react";
import { supabase } from "../lib/supabase";
import { Tag, Search, RefreshCw, CheckCircle, Package } from "lucide-react";

export interface ProductItem {
  id: string;
  shop_id: string;
  title: string;
  description: string;
  base_price: number;
  min_bargain_price: number;
  bargain_enabled: boolean;
  status: string;
  product_variants?: any[];
}

export default function CatalogOversight() {
  const [products, setProducts] = useState<ProductItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  async function fetchProducts() {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from("products")
        .select("*, product_variants(*)")
        .order("created_at", { ascending: false });
      if (error) throw error;
      setProducts((data as ProductItem[]) || []);
    } catch (e) {
      console.error("Error loading products:", e);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchProducts();
  }, []);

  const filtered = products.filter(
    (p) =>
      p.title.toLowerCase().includes(search.toLowerCase()) ||
      (p.description?.toLowerCase().includes(search.toLowerCase()) ?? false)
  );

  return (
    <div>
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "24px", flexWrap: "wrap", gap: "16px" }}>
        <div>
          <h2 style={{ fontSize: "20px", fontWeight: "700", color: "#f8fafc", margin: 0 }}>
            Product Catalog &amp; Bargain Floor Controls
          </h2>
          <p style={{ color: "#94a3b8", fontSize: "13px", marginTop: "4px" }}>
            Monitor listed apparel, inventory stock levels, and minimum acceptable bargaining price thresholds.
          </p>
        </div>
        <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
          <div style={{ position: "relative" }}>
            <Search size={16} color="#64748b" style={{ position: "absolute", left: "12px", top: "10px" }} />
            <input
              type="text"
              placeholder="Search product title..."
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
            onClick={fetchProducts}
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

      {/* Products Grid */}
      {loading ? (
        <div style={{ padding: "48px", textAlign: "center", color: "#94a3b8", backgroundColor: "#131b2e", borderRadius: "12px" }}>
          Loading products from Supabase...
        </div>
      ) : filtered.length === 0 ? (
        <div style={{ padding: "48px", textAlign: "center", color: "#94a3b8", backgroundColor: "#131b2e", borderRadius: "12px" }}>
          No products found matching "{search}".
        </div>
      ) : (
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))", gap: "20px" }}>
          {filtered.map((prod) => (
            <div
              key={prod.id}
              style={{
                backgroundColor: "#131b2e",
                border: "1px solid #1e293b",
                borderRadius: "14px",
                padding: "20px",
                display: "flex",
                flexDirection: "column",
              }}
            >
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "8px" }}>
                <h3 style={{ fontSize: "16px", fontWeight: "700", color: "#ffffff", margin: 0 }}>
                  {prod.title}
                </h3>
                <span
                  style={{
                    backgroundColor: prod.status === "active" ? "#064e3b" : "#7f1d1d",
                    color: prod.status === "active" ? "#6ee7b7" : "#fca5a5",
                    padding: "3px 8px",
                    borderRadius: "4px",
                    fontSize: "11px",
                    fontWeight: "600",
                    textTransform: "uppercase",
                  }}
                >
                  {prod.status}
                </span>
              </div>

              <p style={{ color: "#94a3b8", fontSize: "13px", marginBottom: "16px", lineHeight: "1.4" }}>
                {prod.description}
              </p>

              {/* Pricing Cards */}
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "10px", padding: "12px", backgroundColor: "#0f172a", borderRadius: "8px", marginBottom: "16px" }}>
                <div>
                  <span style={{ fontSize: "11px", color: "#64748b" }}>Base Retail Price</span>
                  <div style={{ fontSize: "16px", fontWeight: "700", color: "#ffffff" }}>
                    ₹{prod.base_price?.toLocaleString("en-IN")}
                  </div>
                </div>
                <div>
                  <span style={{ fontSize: "11px", color: "#64748b" }}>Min Bargain Floor</span>
                  <div style={{ fontSize: "16px", fontWeight: "700", color: "#eab308" }}>
                    ₹{prod.min_bargain_price?.toLocaleString("en-IN")}
                  </div>
                </div>
              </div>

              {/* Variants Section */}
              <div style={{ marginTop: "auto" }}>
                <span style={{ fontSize: "12px", fontWeight: "600", color: "#cbd5e1", display: "flex", alignItems: "center", gap: "6px", marginBottom: "8px" }}>
                  <Package size={14} color="#38bdf8" /> Size &amp; Color Variants ({prod.product_variants?.length || 0})
                </span>
                <div style={{ display: "flex", flexWrap: "wrap", gap: "6px" }}>
                  {(prod.product_variants || []).map((v) => (
                    <span
                      key={v.id}
                      style={{
                        backgroundColor: "#1e293b",
                        color: "#cbd5e1",
                        fontSize: "11px",
                        padding: "4px 8px",
                        borderRadius: "4px",
                        border: "1px solid #334155",
                      }}
                    >
                      {v.size} &bull; {v.color} ({v.stock_qty} in stock)
                    </span>
                  ))}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
